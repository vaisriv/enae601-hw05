import os

import astropy.units as u
import matplotlib.pyplot as plt
import numpy as np
import tellurion as tell
from jpype.types import JArray, JClass
from scipy.integrate import solve_ivp

ROOT = os.path.dirname(__file__)
HOUR, DAY = 3600.0, 86400.0  # s
DECAY = 100.0  # km, altitude treated as decay (Curtis Example 10.1)
COLORS = ("#2a78d6", "#eb6834", "#1baf7a")
plt.rcParams.update(
    {
        "font.size": 9,
        "axes.grid": True,
        "grid.color": "#e1e0d9",
        "axes.spines.top": False,
        "axes.spines.right": False,
        "legend.frameon": False,
        "lines.linewidth": 1.4,
        "savefig.dpi": 200,
    }
)

###############
# Environment #
###############
# Earth constants from Tellurion's (Orekit's) gravity field, so the Cowell runs
# and the variational equations share them. Any epoch works: the density model
# below depends on altitude only.
EPOCH_UTC = "2026-11-18T00:00:00"
EPOCH = tell.abstime(EPOCH_UTC)
TWO_BODY = tell.setgravity(0, 0, mass=100.0)
MU = TWO_BODY["earthmu"].to_value(u.km**3 / u.s**2)  # km^3/s^2
R_E = TWO_BODY["earthrad"].to_value(u.km)  # km
W_E = float(TWO_BODY["earthangspd"])  # rad/s
# Zonal coefficients J_n = -C_n0 of the (slowly time-varying) field at the epoch.
_ZONALS = tell.setgravity(3, 0)["gravity-unnorm"].onDate(
    JClass("org.orekit.time.AbsoluteDate")(
        EPOCH_UTC, JClass("org.orekit.time.TimeScalesFactory").getUTC()
    )
)
J2, J3 = (-float(_ZONALS.getUnnormalizedCnm(n, 0)) for n in (2, 3))

# Spherical satellite of Curtis Example 10.1 (problems 1 and 2d).
DIAMETER, MASS, C_D = 1.0, 100.0, 2.2  # m, kg, -
AREA = np.pi * DIAMETER**2 / 4  # m^2
B = C_D * AREA / MASS  # m^2/kg, ballistic coefficient (Curtis Eq. 10.13)

# US Standard Atmosphere 1976, as tabulated in Curtis's atmosphere.m (App. D.39).
ALT = np.array(
    [0, 25, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 180, 200]
    + [250, 300, 350, 400, 450, 500, 600, 700, 800, 900, 1000],
    dtype=float,
)  # km
RHO = np.array(
    [1.225, 4.008e-2, 1.841e-2, 3.996e-3, 1.027e-3, 3.097e-4, 8.283e-5, 1.846e-5]
    + [3.416e-6, 5.606e-7, 9.708e-8, 2.222e-8, 8.152e-9, 3.831e-9, 2.076e-9]
    + [5.194e-10, 2.541e-10, 6.073e-11, 1.916e-11, 7.014e-12, 2.803e-12]
    + [1.184e-12, 5.215e-13, 1.137e-13, 3.070e-14, 1.136e-14, 5.759e-15, 3.561e-15]
)  # kg/m^3


###########
# Helpers #
###########
def heading(problem: str) -> None:
    print(f"\n------\n {problem}\n------")


def sci(x: float, digits: int = 3) -> str:
    """Scientific notation without exponent padding (e.g. 2.5e-6), for unify."""
    mantissa, exponent = f"{x:.{digits}e}".split("e")
    return f"{mantissa}e{int(exponent)}"


def save_text(name: str, values: dict) -> None:
    """Print and save `key = value` lines, read by the report's `res()` helper."""
    text = "".join(f"{key} = {value}\n" for key, value in values.items())
    os.makedirs(os.path.join(ROOT, "./outputs/text"), exist_ok=True)
    print(text, end="")
    with open(os.path.join(ROOT, f"./outputs/text/s{name}.txt"), "w") as f:
        f.write(text)


def save_fig(fig, name: str) -> None:
    os.makedirs(os.path.join(ROOT, "./outputs/figures"), exist_ok=True)
    fig.savefig(os.path.join(ROOT, f"./outputs/figures/s{name}.png"))


def density(z):
    """USSA76 density (kg/m^3) at altitude z (km). Curtis's exponential interpolation
    between table rows is linear interpolation of ln(rho); zero above the 1000 km top."""
    return np.exp(np.interp(z, ALT, np.log(RHO), right=-np.inf))


def with_drag(env: dict, rotating: bool) -> dict:
    """Add USSA76 drag on the Example 10.1 sphere to a Tellurion force environment.
    Orekit's Harris-Priester model with equal min/max density columns has no diurnal
    bulge and interpolates exactly like `density()`. Its spherical earth is fixed in
    ITRF (air co-rotates) or EME2000 (air at rest)."""
    frame = env["earthframe"] if rotating else env["celestialframe"]
    sphere = JClass("org.orekit.bodies.OneAxisEllipsoid")(R_E * 1e3, 0.0, frame)
    table = JArray.of(np.column_stack((ALT * 1e3, RHO, RHO)))
    atmosphere = JClass("org.orekit.models.earth.atmosphere.HarrisPriester")(
        env["sun"], sphere, table
    )
    shape = JClass("org.orekit.forces.drag.IsotropicDrag")(AREA, C_D)
    return env | {
        "dragforce": JClass("org.orekit.forces.drag.DragForce")(atmosphere, shape)
    }


def kepler_state(rp, ra, raan, inc, argp, ta):
    """Tellurion element set from perigee/apogee radii (km) and angles (deg)."""
    elements = {"sma": (rp + ra) / 2 * u.km, "ecc": (ra - rp) / (ra + rp)}
    angles = {"inc": inc, "raan": raan, "argper": argp, "ta": ta}
    return tell.kepler(elements | {k: v * u.deg for k, v in angles.items()}, EPOCH)


def cowell(state, span: float, env: dict):
    """Cowell's method with Tellurion's numerical propagator (Orekit DP853), stopping
    if the altitude falls to DECAY. Returns the generator and the time propagated (s)."""
    events = {"altitude": DECAY * u.km, "eclipse": [], "visibility": [], "stm": False}
    gen = tell.prepare(state, span * u.s, events, env, propagator="numerical")
    return gen, tell.timerange(gen).to_value(u.s)


def cowell_elements(gen, times, env: dict) -> dict:
    """Osculating elements (km, rad) sampled from a Tellurion ephemeris."""
    ephemeris = tell.propagate(gen, times * u.s, include_init=False)
    names = {"sma": "a", "ecc": "e", "inc": "inc", "raan": "raan", "argper": "argp"}
    table = tell.tselements(ephemeris, list(names) + ["altper", "altapo"], forceenv=env)
    el = {key: np.asarray(table[name].si.value) for name, key in names.items()}
    el["altp"], el["alta"] = (table[k].to_value(u.km) for k in ("altper", "altapo"))
    el["raan"], el["argp"] = np.unwrap(el["raan"]), np.unwrap(el["argp"])
    el["h"] = np.sqrt(MU * el["a"] / 1e3 * (1 - el["e"] ** 2))
    el["a"] = el["a"] / 1e3
    return el


def gve(t, y, j2=False, drag=False):
    """Gauss' variational equations for y = [h, e, theta, Omega, i, omega]: two-body
    motion plus the J2 terms (Curtis Eq. 10.89, with (2 + e cos theta) in 10.89b) and
    the drag terms for air at rest (Curtis Eq. 10.87). Both are linear in the
    perturbing acceleration, so their rates add."""
    h, e, th, _, inc, w = y
    ct, st = np.cos(th), np.sin(th)
    r = h**2 / (MU * (1 + e * ct))
    rates = np.array([0.0, 0.0, h / r**2, 0.0, 0.0, 0.0])
    if j2:
        k = 1.5 * J2 * MU * R_E**2 / (h * r**3)
        q = h**2 / (MU * r)
        si2, s2u, su2 = np.sin(inc) ** 2, np.sin(2 * (w + th)), np.sin(w + th) ** 2
        rates += [
            -k * h * si2 * s2u,
            k * (q * st * (3 * si2 * su2 - 1) - s2u * si2 * ((2 + e * ct) * ct + e)),
            k / e * (q * ct * (3 * si2 * su2 - 1) + (2 + e * ct) * s2u * si2 * st),
            -2 * k * su2 * np.cos(inc),
            -0.5 * k * s2u * np.sin(2 * inc),
            k / e * (q * ct * (1 - 3 * si2 * su2) - (2 + e * ct) * s2u * si2 * st + 2 * e * np.cos(inc) ** 2 * su2),
        ]  # fmt: skip
    if drag:
        v = MU / h * np.sqrt(1 + 2 * e * ct + e**2)  # inertial speed, km/s
        brv = B * density(r - R_E) * 1e3 * v  # B rho v, 1/s (B rho in 1/km)
        rates += [-0.5 * brv * h, -brv * (e + ct), brv / e * st, 0, 0, -brv / e * st]
    return rates


# Gauss-Legendre nodes on [0, 2 pi], weighted so sum(W_NU f(NU)) = (1/2pi) int f dnu.
NU, W_NU = np.polynomial.legendre.leggauss(64)
NU, W_NU = np.pi * (NU + 1), W_NU / 2


def chao_platt(t, y, inc, rotation=True, zonals=True):
    """Chao & Platt's averaged equations (Chao & Hoots Eq. 3.57) for the mean elements
    y = [n, e, Omega, omega], with <di/dt> = 0. Drag integrals over true anomaly nu use
    Gaussian quadrature with rho at r(nu) = p / (1 + e cos nu). `rotation` keeps the
    atmospheric rotation; `zonals` keeps the secular J2 and long-period J3 terms."""
    n, e, _, w = y
    a = (MU / n**2) ** (1 / 3)
    p = a * (1 - e**2)
    cn = np.cos(NU)
    q, s = 1 + e * cn, 1 + 2 * e * cn + e**2
    k = W_E / n * (1 - e**2) ** 1.5 * np.cos(inc) if rotation else 0.0
    v_star = np.sqrt(s) * (1 - k / s)
    f = W_NU * B * density(p / q - R_E) * 1e3 * v_star / q**2
    n_dot = 1.5 * n**2 * a * np.sum(f * (s - k))
    e_dot = (
        0.5 * n * p * np.sum(f * (-2 * (e + cn) + k * (2 * cn + e + e * cn**2) / q**2))
    )
    raan_dot = w_dot = 0.0
    if zonals:
        si, ci = np.sin(inc), np.cos(inc)
        c = 4 - 5 * si**2
        k2, k3 = n * J2 * (R_E / p) ** 2, 3 / 8 * n * J3 * (R_E / p) ** 3
        e_dot -= k3 * si * c * (1 - e**2) * np.cos(w)
        raan_dot = -1.5 * k2 * ci
        w_dot = 0.75 * k2 * c + k3 * (
            c * (si**2 - e**2 * ci**2) / (e * si) + 2 * si * (13 - 15 * si**2) * e
        ) * np.sin(w)
    return np.array([n_dot, e_dot, raan_dot, w_dot])


def integrate(rates, y0, span, stop=None, rtol=1e-10):
    """DOP853 integration of dy/dt = rates(t, y) over [0, span]; `stop(t, y)` ends it
    when it crosses zero downward."""
    if stop is not None:
        setattr(stop, "terminal", True)
        setattr(stop, "direction", -1)
    return solve_ivp(rates, (0, span), y0, method="DOP853", rtol=rtol, atol=1e-12,
                     events=stop, dense_output=True)  # fmt: skip


def gve_elements(sol, times) -> dict:
    """Elements and perigee/apogee altitudes from a Gauss-equation solution."""
    h, e, _, raan, inc, argp = sol.sol(times)
    p = h**2 / MU
    return {"h": h, "e": e, "raan": raan, "inc": inc, "argp": argp,
            "a": p / (1 - e**2), "altp": p / (1 + e) - R_E, "alta": p / (1 - e) - R_E}  # fmt: skip


def altitude_figure(name, curves, title):
    """Perigee and apogee altitude against time; curves = [(t, el, label, style)]."""
    fig, ax = plt.subplots(figsize=(6.5, 3.4), layout="constrained")
    for t, el, label, style in curves:
        ax.plot(t / DAY, el["alta"], label=label, **style)
        ax.plot(t / DAY, el["altp"], **style)
    t, el = curves[0][:2]
    k = len(t) // 4
    ax.annotate(
        "apogee", (t[k] / DAY, el["alta"][k]), xytext=(0, 6), textcoords="offset points"
    )
    ax.annotate("perigee", (t[k] / DAY, el["altp"][k]), xytext=(0, -12), textcoords="offset points")  # fmt: skip
    ax.axhline(DECAY, color="0.5", lw=0.8, ls="--")
    ax.set(xlabel="time (days)", ylabel="altitude (km)", title=title, ylim=(0, 1000), xlim=(0, None))  # fmt: skip
    if len(curves) > 1:
        ax.legend(loc="upper right")
    save_fig(fig, name)


# (key, symbol, unit of the change, unit of the difference, scale to that unit)
PANELS = (
    ("raan", r"\Omega", "deg", "arcsec", 3600),
    ("argp", r"\omega", "deg", "arcsec", 3600),
    ("h", "h", "km$^2$/s", "km$^2$/s", 1),
    ("e", "e", "-", "-", 1),
    ("inc", "i", "deg", "arcsec", 3600),
)


def change(el, key):
    """Change of an element from its initial value (angles in degrees)."""
    x = el[key] - el[key][0]
    return np.degrees(x) if key in ("raan", "argp", "inc") else x


def elements_figure(name, hours, series, diff=None):
    """Element changes as in Curtis Fig. 10.13; series = [(el, label, style)]. With
    diff = (el1, el0, label), a second column plots el1 - el0."""
    fig, axes = plt.subplots(5, 2 if diff else 1, figsize=(6.5, 6.2), sharex=True, squeeze=False, layout="constrained")  # fmt: skip
    for row, (key, sym, unit, dunit, scale) in enumerate(PANELS):
        for el, label, style in series:
            axes[row, 0].plot(hours, change(el, key), label=label, **style)
        axes[row, 0].set_ylabel(rf"$\Delta {sym}$ ({unit})")
        if diff:
            delta = change(diff[0], key) - change(diff[1], key)
            axes[row, 1].plot(hours, scale * delta, color=COLORS[2])
            axes[row, 1].set_ylabel(rf"$\delta {sym}$ ({dunit})")
    if diff:
        axes[0, 1].set_title(diff[2])
    if len(series) > 1:
        fig.legend(
            *axes[0, 0].get_legend_handles_labels(), loc="outside upper center", ncols=2
        )
    for ax in axes[-1]:
        ax.set(xlabel="time (h)", xlim=(0, hours[-1]))
    for column in axes.T:
        fig.align_ylabels(column)
    save_fig(fig, name)


def main() -> None:
    #########
    # p01 #
    #########
    # Curtis Example 10.1 orbit.
    rp, ra = 6593.0, 7317.0  # km
    raan, inc, argp, ta = 340.0, 65.1, 58.0, 332.0  # deg
    a0, e0 = (rp + ra) / 2, (ra - rp) / (ra + rp)
    h0 = np.sqrt(MU * a0 * (1 - e0**2))
    state = kepler_state(rp, ra, raan, inc, argp, ta)
    horizon = 200 * DAY

    #########
    # p01a #
    #########
    heading("p01a")
    # Two-body gravity and drag in air at rest (the forces of Eq. 10.87), then the
    # same with co-rotating air as in Example 10.1, to check against Curtis's 108 days.
    gen_a, t_a = cowell(state, horizon, with_drag(TWO_BODY, rotating=False))
    _, t_rot = cowell(state, horizon, with_drag(TWO_BODY, rotating=True))
    times_a = np.linspace(0, t_a, 1500)
    cow = cowell_elements(gen_a, times_a, TWO_BODY)
    save_text(
        "01a",
        {
            "mu": f"{MU:.4f}",
            "R_E": f"{R_E:.4f}",
            "A": f"{AREA:.4f}",
            "B": f"{B:.5f}",
            "a0": f"{a0:.1f}",
            "e0": f"{e0:.6f}",
            "h0": f"{h0:.1f}",
            "rho_p": sci(float(density(rp - R_E))),
            "rho_a": sci(float(density(ra - R_E))),
            "decay": f"{t_a / DAY:.2f}",
            "decay_rot": f"{t_rot / DAY:.2f}",
        },
    )
    altitude_figure(
        "01a",
        [(times_a, cow, None, {"color": COLORS[0]})],
        "Cowell's method (Tellurion), two-body + drag",
    )

    #########
    # p01b #
    #########
    heading("p01b")

    def decayed(t, y):  # altitude from the orbit equation, minus DECAY
        return y[0] ** 2 / (MU * (1 + y[1] * np.cos(y[2]))) - R_E - DECAY

    y0 = np.array([h0, e0, *np.radians([ta, raan, inc, argp])])
    sol_b = integrate(lambda t, y: gve(t, y, drag=True), y0, horizon, stop=decayed)
    t_b = sol_b.t_events[0][0]
    times_b = np.linspace(0, t_b, 3000)
    gauss = gve_elements(sol_b, times_b)
    save_text(
        "01b",
        {
            "decay": f"{t_b / DAY:.2f}",
            "decay_diff": f"{(t_b - t_a) / 60:.1f}",
            "min_e": f"{np.min(sol_b.y[1]):.5f}",
        },
    )  # fmt: skip
    altitude_figure(
        "01b",
        [(times_b, gauss, None, {"color": COLORS[1]})],
        "Gauss' variational equations (Curtis Eq. 10.87)",
    )

    #########
    # p01c #
    #########
    heading("p01c")
    # Initial mean elements are taken equal to the given (osculating) elements.
    y0_c = np.array([np.sqrt(MU / a0**3), e0, np.radians(raan), np.radians(argp)])

    def mean_perigee(t, y):  # mean perigee altitude a (1 - e) - R_E, minus DECAY
        return (MU / y[0] ** 2) ** (1 / 3) * (1 - y[1]) - R_E - DECAY

    def chao(**flags):
        rates = lambda t, y: chao_platt(t, y, np.radians(inc), **flags)  # noqa: E731
        sol = integrate(rates, y0_c, horizon, stop=mean_perigee)
        return sol, sol.t_events[0][0]

    sol_c, t_c = chao()
    times_c = np.linspace(0, t_c, 3000)
    n, e = sol_c.sol(times_c)[:2]
    a = (MU / n**2) ** (1 / 3)
    mean = {"altp": a * (1 - e) - R_E, "alta": a * (1 + e) - R_E}
    rates0 = chao_platt(0, y0_c, np.radians(inc))
    save_text(
        "01c",
        {
            "J2": sci(J2, 6),
            "J3": sci(J3, 4),
            "w_E": sci(W_E, 6),
            "rot": f"{W_E / y0_c[0] * (1 - e0**2) ** 1.5 * np.cos(np.radians(inc)):.4f}",
            "ndot0": sci(rates0[0], 3),
            "edot0": sci(rates0[1] * DAY, 3),
            "raandot0": f"{np.degrees(rates0[2]) * DAY:.3f}",
            "argpdot0": f"{np.degrees(rates0[3]) * DAY:.3f}",
            "decay": f"{t_c / DAY:.2f}",
            "argp_end": f"{np.degrees(sol_c.y[3][-1]):.1f}",
        },
    )
    altitude_figure(
        "01c",
        [(times_c, mean, None, {"color": COLORS[2]})],
        "Chao & Platt averaged equations (Chao & Hoots Eq. 3.57)",
    )

    #########
    # p01d #
    #########
    heading("p01d")
    # Switch off Eq. 3.57's extra physics one piece at a time to explain the differences.
    _, t_drag = chao(rotation=False, zonals=False)
    _, t_crot = chao(zonals=False)
    save_text(
        "01d",
        {
            "cowell": f"{t_a / DAY:.2f}",
            "gauss": f"{t_b / DAY:.2f}",
            "chao_drag": f"{t_drag / DAY:.2f}",
            "chao_rot": f"{t_crot / DAY:.2f}",
            "chao": f"{t_c / DAY:.2f}",
            "rot_gain": f"{(t_crot - t_drag) / DAY:.2f}",
            "zonal_gain": f"{(t_c - t_crot) / DAY:.2f}",
        },
    )
    altitude_figure(
        "01d",
        [
            (times_a, cow, "Part A: Cowell", {"color": COLORS[0]}),
            (
                times_b,
                gauss,
                "Part B: Gauss, Eq. 10.87",
                {"color": COLORS[1], "ls": "--"},
            ),
            (times_c, mean, "Part C: Chao & Platt, Eq. 3.57", {"color": COLORS[2]}),
        ],
        "Perigee and apogee altitude, all three methods",
    )

    #########
    # p02 #
    #########
    # Curtis Example 10.2/10.6 orbit (r_a = 9440 km; Ex. 10.2's 9940 is a misprint).
    rp, ra = 6678.0, 9440.0  # km
    raan, inc, argp, ta = 45.0, 28.0, 30.0, 40.0  # deg
    a0, e0 = (rp + ra) / 2, (ra - rp) / (ra + rp)
    h0 = np.sqrt(MU * a0 * (1 - e0**2))
    span = 48 * HOUR
    times = np.linspace(0, span, 1001)
    hours = times / HOUR
    y0 = np.array([h0, e0, *np.radians([ta, raan, inc, argp])])

    def rate(el, key):  # least-squares secular rate, deg/h
        return float(np.polyfit(hours, np.degrees(el[key]), 1)[0])

    #########
    # p02a #
    #########
    heading("p02a")
    # Degree-2 zonal field, evaluated with its axis on EME2000 Z (as in Eq. 10.30)
    # rather than ITRF's pole, which has precessed ~0.15 deg since J2000.
    j2_env = tell.setgravity(2, 0, mass=MASS)
    j2_env = j2_env | {"earthframe": j2_env["celestialframe"]}
    gen, _ = cowell(kepler_state(rp, ra, raan, inc, argp, ta), span, j2_env)
    cow = cowell_elements(gen, times, j2_env)
    pvt0 = tell.propagate(gen, 0 * u.s, include_init=False, output="pvt")
    r0 = pvt0.position_vector.to_value(u.km).ravel()
    v0 = pvt0.velocity_vector.to_value(u.km / u.s).ravel()
    save_text(
        "02a",
        {
            "a0": f"{a0:.1f}",
            "e0": f"{e0:.5f}",
            "h0": f"{h0:.0f}",
            "T0": f"{2 * np.pi * np.sqrt(a0**3 / MU) / HOUR:.4f}",
            **{f"r0_{c}": f"{x:.2f}" for c, x in zip("xyz", r0)},
            **{f"v0_{c}": f"{x:.5f}" for c, x in zip("xyz", v0)},
            "dOmega": f"{change(cow, 'raan')[-1]:.3f}",
            "domega": f"{change(cow, 'argp')[-1]:.3f}",
            "Omega_rate": f"{rate(cow, 'raan'):.4f}",
            "omega_rate": f"{rate(cow, 'argp'):.4f}",
        },
    )
    elements_figure("02a", hours, [(cow, "Part A: Cowell", {"color": COLORS[0]})])

    #########
    # p02b #
    #########
    heading("p02b")
    gauss = gve_elements(integrate(lambda t, y: gve(t, y, j2=True), y0, span, rtol=1e-12), times)  # fmt: skip

    def max_diff(key, scale=1.0):  # largest |Part B - Part A| in the element's change
        return sci(scale * np.max(np.abs(change(gauss, key) - change(cow, key))), 1)

    save_text(
        "02b",
        {
            "dOmega": f"{change(gauss, 'raan')[-1]:.3f}",
            "domega": f"{change(gauss, 'argp')[-1]:.3f}",
            "Omega_rate": f"{rate(gauss, 'raan'):.4f}",
            "omega_rate": f"{rate(gauss, 'argp'):.4f}",
            "diff_Omega": max_diff("raan", 3600),
            "diff_omega": max_diff("argp", 3600),
            "diff_h": max_diff("h"),
            "diff_e": max_diff("e"),
            "diff_i": max_diff("inc", 3600),
        },
    )
    elements_figure(
        "02b",
        hours,
        [
            (cow, "Part A: Cowell", {"color": COLORS[0]}),
            (gauss, "Part B: Gauss, Eq. 10.89", {"color": COLORS[1], "ls": "--"}),
        ],
    )

    #########
    # p02c #
    #########
    heading("p02c")
    # Lagrange's planetary equations (Curtis Eq. 10.50) with the orbit-averaged J2
    # disturbing function R = mu J2 R_E^2 (2 - 3 sin^2 i) / (4 a^3 (1 - e^2)^(3/2)),
    # which depends on a, e, i only, so dR/dt_p = dR/dOmega = dR/domega = 0.
    i0, n0 = np.radians(inc), np.sqrt(MU / a0**3)
    G = np.sqrt(MU * a0 * (1 - e0**2))
    R = MU * J2 * R_E**2 * (2 - 3 * np.sin(i0) ** 2) / (4 * a0**3 * (1 - e0**2) ** 1.5)
    dR_da, dR_de = -3 * R / a0, 3 * e0 * R / (1 - e0**2)
    dR_di = -3 * MU * J2 * R_E**2 * np.sin(i0) * np.cos(i0) / (2 * a0**3 * (1 - e0**2) ** 1.5)  # fmt: skip
    raan_dot = dR_di / (G * np.sin(i0))
    argp_dot = -dR_di / (G * np.tan(i0)) + np.sqrt(1 - e0**2) / (np.sqrt(MU * a0) * e0) * dR_de  # fmt: skip
    tp_dot = 2 * a0**2 / MU * dR_da + a0 * (1 - e0**2) / (MU * e0) * dR_de
    deg_h = np.degrees(1) * HOUR  # rad/s -> deg/h
    save_text(
        "02c",
        {
            "n0": sci(n0, 5),
            "R": f"{R:.6f}",
            "dR_da": sci(dR_da, 4),
            "dR_de": f"{dR_de:.6f}",
            "dR_di": f"{dR_di:.6f}",
            "Omega_rate_rad": sci(raan_dot, 4),
            "omega_rate_rad": sci(argp_dot, 4),
            "Omega_rate": f"{raan_dot * deg_h:.4f}",
            "omega_rate": f"{argp_dot * deg_h:.4f}",
            "tp_rate": sci(tp_dot, 4),
            "M_rate": f"{-n0 * tp_dot * deg_h:.4f}",
            "Omega_48h": f"{raan_dot * deg_h * 48:.3f}",
            "omega_48h": f"{argp_dot * deg_h * 48:.3f}",
        },
    )

    #########
    # p02d #
    #########
    heading("p02d")
    rates = lambda t, y: gve(t, y, j2=True, drag=True)  # noqa: E731
    both = gve_elements(integrate(rates, y0, span, rtol=1e-12), times)

    def drag_effect(key, scale=1.0, digits=3):  # (J2 + drag) - (J2 only) after 48 h
        return f"{scale * (both[key][-1] - gauss[key][-1]):.{digits}f}"

    def drag_max(key):  # largest |(J2 + drag) - (J2 only)| over 48 h, arcsec
        return f"{3600 * np.max(np.abs(change(both, key) - change(gauss, key))):.2f}"

    save_text(
        "02d",
        {
            "rho_p": sci(float(density(rp - R_E))),
            "dh": drag_effect("h"),
            "de": sci(both["e"][-1] - gauss["e"][-1], 2),
            "da": drag_effect("a"),
            "dalta": drag_effect("alta"),
            "daltp": drag_effect("altp", digits=4),
            "max_dOmega": drag_max("raan"),
            "max_domega": drag_max("argp"),
            "max_di": drag_max("inc"),
            "h_range": f"{np.ptp(gauss['h']):.2f}",
        },
    )
    elements_figure(
        "02d",
        hours,
        [
            (cow, "Part A: Cowell, $J_2$", {"color": COLORS[0]}),
            (both, "Part D: Gauss, $J_2$ + drag", {"color": COLORS[1], "ls": "--"}),
        ],
        diff=(both, gauss, "drag effect: Part D $-$ Part B"),
    )

    plt.show()


if __name__ == "__main__":
    main()
