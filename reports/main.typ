/////////////
// Imports //
/////////////
#import "@preview/adaptable-pset:0.2.0": *
#import "@preview/physica:0.9.8": *
#import "@preview/unify:0.8.1": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(languages: codly-languages)

/////////////////
// Maths Setup //
/////////////////

// upright vectors
#let vectorboldupright(a) = vb($upright(#a)$)
#let vbu = vectorboldupright
#let vectorunitupright(a) = vu($upright(#a)$)
#let vuu = vectorunitupright
#let vectorarrowupright(a) = va($upright(#a)$)
#let vau = vectorarrowupright

// automatically use square brackets for vectors and matricies
#set math.vec(delim: "[")
#set math.mat(delim: "[")
#let vecrowOld = vecrow
#let vecrow = vecrowOld.with(delim: "[")

// custom units
#add-unit("decibelIsotropic", "dBi", "upright(\"dBi\")", space: true)
#add-unit("decibelWatt", "dBW", "upright(\"dBW\")", space: true)

// script outputs: the value of a `name = value` line in ../outputs/text/s<part>.txt
#let res(part, name) = {
    let line = read("../outputs/text/s" + part + ".txt")
        .split("\n")
        .find(l => l.starts-with(name + " = "))
    line.slice(name.len() + 3)
}

////////////////////
// Document Setup //
////////////////////

// assignment info
#show: homework.with(
    title: "HW05",
    author: "Vai Srivastava",
    collaborators: [],
    course-id: "ENAE 601: Astrodynamics",
    instructor: "Dr. Healy",
    semester: "Fall 2026",
    due-time: datetime(
        // due date
        year: 2026,
        month: 11,
        day: 18,

        // due time
        hour: 23,
        minute: 59,
        second: 00,
    ).display(
        "[month repr:long] [day padding:zero], [year] at [hour repr:24]:[minute padding:zero]:[second padding:zero]",
    ),

    // (defaults to A4)
    paper-size: "us-letter",
)

// document settings
#set text(font: "New Computer Modern", size: 10pt)
#set enum(numbering: "a)")

// problem headings
#let probOld = prob
#let prob = prob.with(color: black)

////////////////////////////
// The Assignment Itself: //
// Problems and Solutions //
////////////////////////////

#prob(title: [Lifetime of a satellite with atmospheric drag #emph[(12 pts)]])[
    // See Example 10.1 on page 486 for the orbit.

    A small spherical earth satellite has a diameter of #qty(1, "m") and a mass of #qty(100, "kg"). At a given time $t_0$, its orbital parameters are:
    $
        &"Perigee radius:" &quad r_p &= #qty(6593, "km") (#qty(215, "km") "altitude") \
        &"Apogee radius:" &quad r_a &= #qty(7317, "km") (#qty(939, "km") "altitude") \
        &"Right ascension of the ascending node:" &quad Omega &= #qty(340, "deg") \
        &"Inclination:" &quad i &= #qty(65.1, "deg") \
        &"Argument of perigee:" &quad omega &= #qty(58, "deg") \
        &"True anomaly:" &quad theta &= #qty(332, "deg")
    $
    You may use any atmospheric density model you want, but use the same one across all parts.

    +
        Propagate this orbit numerically until it decays. Plot the altitude with time.
        #emph[(3 pts)]
    <hwk:p01a>

    +
        Use the Gauss variational equations (Curtis eq. 10.87) to do the same calculation.
        #emph[(3 pts)]
    <hwk:p01b>

    +
        Integrate including atmospheric rotation and zonal coefficients per Chao and Platt's. See Section 3.6 of #link("https://umaryland.on.worldcat.org/oclc/1112606368")[Chao & Hoots "Applied Orbit Perturbation and Maintenance" (2018, 2nd. Edition)].
        #emph[(4 pts)]

    // #emph[#smallcaps[Note:] Even though this link is to the second edition, when you select "View eBook", it brings you to the first edition. You will need to click on the title, then "see other editions", then select the second edition.]
    <hwk:p01c>

    +
        Plot all three on the same graph and interpret the results.
        #emph[(2 pts)]
    <hwk:p01d>
] <hwk:p01>

+
    The satellite is the sphere of Curtis Example 10.1, which uses $C_D = 2.2$. Its frontal area and ballistic coefficient (Curtis Eq. 10.13) are:
    $
        A = (pi d^2)/4 = qty(res("01a", "A"), "m^2"), quad B = (C_D A)/m = qty(res("01a", "B"), "m^2/kg")
    $
    Every part uses Tellurion's (Orekit's) earth constants, $mu = qty(res("01a", "mu"), "km^3/s^2")$ and $R_E = qty(res("01a", "R_E"), "km")$. From the given radii:
    $
        e = (r_a - r_p)/(r_a + r_p) = num(res("01a", "e0")), quad a = (r_a + r_p)/2 = qty(res("01a", "a0"), "km"), quad h = sqrt(mu a (1 - e^2)) = qty(res("01a", "h0"), "km^2/s")
    $

    #emph[Density model:] Every part uses the 1976 US Standard Atmosphere as tabulated in Curtis's `atmosphere.m` (App. D.39), which interpolates exponentially between 28 altitudes $z_i$ from 0 to #qty(1000, "km"):
    $
        rho(z) = rho_i exp(-(z - z_i)/H_i), quad H_i = (z_(i+1) - z_i)/ln(rho_i \/ rho_(i+1)), quad z_i <= z < z_(i+1)
    $
    Here $z = r - R_E$ is the altitude above a spherical earth, and $rho = 0$ above the top of the table. The density is $qty(res("01a", "rho_p"), "kg/m^3")$ at perigee and $qty(res("01a", "rho_a"), "kg/m^3")$ at apogee.

    #emph[Cowell's method:] The equation of motion is Curtis Eq. 10.2 with the drag acceleration of Eq. 10.12:
    $
        dot.double(vbu(r)) = -mu vbu(r)/r^3 - 1/2 rho B v_"rel" vbu(v)_"rel", quad vbu(v)_"rel" = vbu(v)
    $
    The air is held at rest, the assumption behind Curtis Eq. 10.87, so Parts A and B model the same forces; atmospheric rotation enters in Part C. Tellurion's numerical propagator (Orekit's Dormand--Prince 8(5,3) integrator) integrates this with point-mass gravity, `tell.setgravity(0, 0)`, from the given elements. The drag is Orekit's `DragForce` on the sphere. Its atmosphere is Orekit's Harris--Priester model loaded with the USSA76 table as both its minimum and its maximum density, which removes the diurnal bulge and reproduces $rho(z)$ exactly. That model's earth is a sphere fixed in the inertial EME2000 frame, so the air does not move. Tellurion's altitude event stops the propagation at #qty(100, "km"), which Curtis treats as decay.

    #figure(
        image("../outputs/figures/s01a.png", width: 85%),
        caption: [Osculating perigee and apogee altitude from Cowell's method: the lowest and highest altitude on each orbit, as in Curtis Fig. 10.5.],
    ) <fig:s01a>

    Drag acts mostly near perigee, where the air is about $10^4$ times denser than at apogee. Each perigee pass removes energy, which lowers the apogee while the perigee barely moves, so drag circularizes the orbit. Once the orbit is nearly circular, all of it is in dense air, and it decays within days. The satellite reaches #qty(100, "km") after:
    $
        t_"decay" = qty(res("01a", "decay"), "d") quad qed
    $
    As a check, fixing the atmosphere's sphere in the rotating ITRF frame instead (co-rotating air, $vbu(v)_"rel" = vbu(v) - vbu(omega)_E times vbu(r)$, as in Curtis Example 10.1) gives #qty(res("01a", "decay_rot"), "d"). That matches Curtis's 108 days.
<hwk:s01a>

+
    The Gauss variational equations are:
    $
            dv(h, t) & = - B/2 h rho v \
            dv(e, t) & = - B (e + cos(theta)) rho v \
        dv(theta, t) & = h/r^2 + B (rho v)/e sin(theta) \
        dv(Omega, t) & = 0 \
            dv(i, t) & = 0 \
        dv(omega, t) & = - B (rho v)/e sin(theta)
    $
    where $v$ is the inertial speed and $r$ the radius,
    $
        v = mu/h sqrt(1 + 2 e cos(theta) + e^2), quad r = h^2/mu 1/(1 + e cos(theta))
    $
    $rho = rho(r - R_E)$ is the USSA76 model, and $B$ is from Part A. SciPy's DOP853 integrator (relative tolerance $10^(-10)$) advances $vecrow(h, e, theta, Omega, i, omega)$ from the given elements until $r - R_E = qty(100, "km")$. The perigee and apogee radii are $r_(p, a) = h^2 \/ [mu (1 plus.minus e)]$.

    #figure(
        image("../outputs/figures/s01b.png", width: 85%),
        caption: [Perigee and apogee altitude from Gauss' variational equations (Curtis Eq. 10.87).],
    ) <fig:s01b>

    The satellite reaches #qty(100, "km") after:
    $
        t_"decay" = qty(res("01b", "decay"), "d") quad qed
    $
    This is #qty(res("01b", "decay_diff"), "min") later than Part A. Eq. 10.87 rewrites the same forces in osculating elements without approximation, so the two methods differ only by integration error. The eccentricity is still #num(res("01b", "min_e")) at decay, so the $1 \/ e$ terms stay bounded.
<hwk:s01b>

+
    Chao & Hoots (Section 3.6) average the drag perturbation over one orbit, in mean elements. For lifetime studies, Chao and Platt simplify the averaged equations:
    - Keep only the secular $J_2$ terms and the long-period $J_3$ terms (dropping $J_2^2$, $J_4$, and $e J_3$ terms).
    - Ignore atmospheric rotation in $dot(dotless.i)$ and $dot(Omega)$.
    - Ignore drag in $dot(omega)$, which nearly cancels an opposite effect on $M$.
    - Ignore second-order atmospheric rotation terms in the velocity.

    With mean elements $n$, $e$, $i$, $Omega$, $omega$, $a = (mu \/ n^2)^(1\/3)$, $p = a (1 - e^2)$, and $B = C_D A \/ m$, their Eq. 3.57 is:
    #show math.equation: set block(breakable: true)
    $
        expval(dv(n, t)) &= (3 n^2 a)/2 B 1/(2 pi) integral_0^(2 pi) (rho V^*)/(1 + e cos nu)^2 [1 + e cos nu + e (cos nu + e) - (omega_e (1 - e^2)^(3\/2))/n cos i] dd(nu) \
        expval(dv(e, t)) &= (n p)/2 B 1/(2 pi) integral_0^(2 pi) (rho V^*)/(1 + e cos nu)^2 [-2 (e + cos nu) + (omega_e (1 - e^2)^(3\/2))/n cos i (2 cos nu + e + e cos^2 nu)/(1 + e cos nu)^2] dd(nu) \
        &quad - 3/8 n J_3 (R_E/p)^3 sin i (4 - 5 sin^2 i) (1 - e^2) cos omega \
        expval(dv(i, t)) &= 0 \
        expval(dv(Omega, t)) &= -3/2 n J_2 (R_E/p)^2 cos i \
        expval(dv(omega, t)) &= 3/4 n J_2 (R_E/p)^2 (4 - 5 sin^2 i) \
        &quad + 3/8 n J_3 (R_E/p)^3 [(4 - 5 sin^2 i) (sin^2 i - e^2 cos^2 i)/(e sin i) + 2 sin i (13 - 15 sin^2 i) e] sin omega
    $
    where $nu$ is the true anomaly,
    $
        V^* = sqrt(1 + 2 e cos nu + e^2) [1 - (1 - e^2)^(3\/2)/(1 + 2 e cos nu + e^2) omega_e/n cos i]
    $
    is the speed relative to the co-rotating atmosphere in units of $n a \/ sqrt(1 - e^2)$, $omega_e$ is the earth's (and atmosphere's) rotation rate, and $rho = rho(r(nu) - R_E)$ with $r(nu) = p \/ (1 + e cos nu)$.

    The constants come from the same Tellurion gravity field: $J_2 = num(res("01c", "J2"))$, $J_3 = num(res("01c", "J3"))$, and $omega_e = qty(res("01c", "w_E"), "rad/s")$. The integrals over $nu$ use 64-point Gauss--Legendre quadrature, as Chao & Hoots suggest. SciPy's DOP853 integrator advances $vecrow(n, e, Omega, omega)$ with $i$ fixed; its steps grow to many orbital periods, since the averaged rates vary slowly. Only osculating elements are given, so the initial mean elements are taken equal to them, which ignores the small short-period offset between the two. Integration stops when the mean perigee altitude $a (1 - e) - R_E$ reaches #qty(100, "km"), the same criterion as Parts A and B. The initial rates are:
    $
        expval(dot(n)) &= qty(res("01c", "ndot0"), "rad/s^2"), quad & expval(dot(e)) &= qty(res("01c", "edot0"), "/d"), \
        expval(dot(Omega)) &= qty(res("01c", "raandot0"), "deg/d"), quad & expval(dot(omega)) &= qty(res("01c", "argpdot0"), "deg/d")
    $

    #figure(
        image("../outputs/figures/s01c.png", width: 85%),
        caption: [Mean perigee and apogee altitude from Chao & Platt's averaged equations (Chao & Hoots Eq. 3.57).],
    ) <fig:s01c>

    The satellite reaches #qty(100, "km") after:
    $
        t_"decay" = qty(res("01c", "decay"), "d") quad qed
    $
    Two effects slow the decay compared with Parts A and B. Co-rotating air moves with this prograde satellite, which lowers the relative speed by about $(omega_e \/ n)(1 - e^2)^(3\/2) cos i = #num(res("01c", "rot"))$ of the speed. And the inclination, #qty(65.1, "deg"), is near the critical #qty(63.4, "deg") where $4 - 5 sin^2 i = 0$, so $omega$ drifts only from #qty(58, "deg") to #qty(res("01c", "argp_end"), "deg") by decay. With $J_3 < 0$, $4 - 5 sin^2 i < 0$, and $cos omega > 0$ throughout, the $J_3$ term in $expval(dot(e))$ stays negative. A smaller $e$ at the same $a$ raises the perigee. The node regresses quickly, but with an altitude-only density it does not affect the decay.
<hwk:s01c>

+
    #figure(
        image("../outputs/figures/s01d.png", width: 85%),
        caption: [Perigee and apogee altitude from all three methods. Part C gives mean elements.],
    ) <fig:s01d>

    The decay times are:
    $
        t_"decay" = qty(res("01d", "cowell"), "d") "(Part A)", quad qty(res("01d", "gauss"), "d") "(Part B)", quad qty(res("01d", "chao"), "d") "(Part C)" quad qed
    $
    To see where Part C's extra days come from, @tab:s01d switches the terms of Eq. 3.57 on one at a time:

    #figure(
        table(
            columns: 2,
            align: (left, right),
            stroke: none,
            table.hline(),
            table.header([*Model*], [*Lifetime (days)*]),
            table.hline(stroke: 0.5pt),
            [Part A: Cowell, air at rest], [#res("01d", "cowell")],
            [Part B: Gauss, air at rest], [#res("01d", "gauss")],
            [Eq. 3.57, drag only (no rotation, no zonals)],
            [#res("01d", "chao_drag")],
            [Eq. 3.57, drag and atmospheric rotation],
            [#res("01d", "chao_rot")],
            [Part C: Eq. 3.57, drag, rotation, $J_2$, $J_3$],
            [#res("01d", "chao")],
            table.hline(),
        ),
        caption: [Time to decay to #qty(100, "km").],
    ) <tab:s01d>

    - Parts A and B model the same forces in different variables, so their curves overlap and their decay times agree to within a minute.
    - Averaging costs nothing here: with rotation and zonals off, Eq. 3.57 also gives #qty(res("01d", "chao_drag"), "d"). Drag changes the orbit very little over one revolution, so the orbit-averaged rates follow the osculating ones.
    - Atmospheric rotation adds #qty(res("01d", "rot_gain"), "d"). The drag force scales with $v_"rel"^2$, so a relative speed lower by about #num(res("01c", "rot")) of the speed cuts drag, and lengthens the lifetime, by about twice that fraction. With rotation, the averaged equations reproduce Curtis's 108 days (Example 10.1) and the rotating Cowell check in Part A.
    - Zonal harmonics add #qty(res("01d", "zonal_gain"), "d"). Secular $J_2$ only turns $Omega$ and $omega$; it does not change $n$ or $e$. So the gain is due to $J_3$, which lowers $e$ and holds the perigee higher, as described in Part C. Near the critical inclination, $J_2$ moves $omega$ so slowly that the $J_3$ term keeps the same sign for the whole lifetime.
<hwk:s01d>

#pagebreak(weak: true)

#prob(title: [$J_2$ effects #emph[(15 pts)]])[
    // See Example 10.2 on page 492 for orbit information. However, do #emph[not] use Encke's method.

    At time $t_0$, an earth satellite has the following orbital parameters:
    $
        &"Perigee radius:" &quad r_p &= #qty(6678, "km") (#qty(300, "km") "altitude") \
        &"Apogee radius:" &quad r_a &= #qty(9940, "km") (#qty(3062, "km") "altitude") \
        &"Right ascension of the ascending node:" &quad Omega &= #qty(45, "deg") \
        &"Inclination:" &quad i &= #qty(28, "deg") \
        &"Argument of perigee:" &quad omega &= #qty(30, "deg") \
        &"True anomaly:" &quad theta &= #qty(40, "deg")
    $

    +
        Integrate the orbit with the two-body force and $J_2$ perturbing force with ordinary numerical integration (not Encke's method).
        #emph[(2 pts)]
    <hwk:p02a>

    +
        Use the Gauss variational equations (Curtis eq. 10.89); see Example 10.6, Page 511. Plot the elements along with the computations from #link(<hwk:p02a>)[Part A]; your result should look something like Figure 10.13.
        #emph[(3 pts)]
    <hwk:p02b>

    +
        Using the Lagrange planetary equations (Curtis eq. 10.50), compute the time rate of change of the elements.
        #emph[(5 pts)]
    <hwk:p02c>

    +
        Using the Gauss equations once again, combine the $J_2$ and atmospheric drag forces and plot together with the result of #link(<hwk:p02a>)[Part A]. Assume the same area, mass, and $C_D$ as in Example 10.1. Interpret the results. What is the effect of the drag force?
        #emph[(5 pts)]
    <hwk:p02d>
] <hwk:p02>

+
    The orbit is that of Curtis Example 10.2. Its apogee radius is printed as #qty(9940, "km"), but the stated #qty(3062, "km") apogee altitude gives $r_a = 6378 + 3062 = qty(9440, "km")$. Curtis's own $e = 0.17136$ and $a = qty(8059, "km")$, and Example 10.6, also require #qty(9440, "km"), so that value is used here. Then:
    $
        e = num(res("02a", "e0")), quad a = qty(res("02a", "a0"), "km"), quad h = sqrt(mu a (1 - e^2)) = qty(res("02a", "h0"), "km^2/s"), quad T = 2 pi sqrt(a^3/mu) = qty(res("02a", "T0"), "h")
    $

    #emph[Cowell's method:] The equation of motion is $dot.double(vbu(r)) = -mu vbu(r) \/ r^3 + vbu(p)$, where $vbu(p)$ is the $J_2$ acceleration of Curtis Eq. 10.30. Tellurion's numerical propagator integrates it for #qty(48, "h") with a degree-2, order-0 gravity field, `tell.setgravity(2, 0)`. The field is evaluated in the EME2000 frame, so its symmetry axis is the $Z$ axis of Eq. 10.30 rather than the ITRF pole, which has precessed about #qty(0.15, "deg") since J2000. Tellurion's `tselements` converts the state at 1001 equally spaced times to osculating elements, with $h = sqrt(mu a (1 - e^2))$. The initial state matches Curtis Example 10.2:
    $
        vbu(r)_0 &= vecrow(num(res("02a", "r0_x")), num(res("02a", "r0_y")), num(res("02a", "r0_z"))) space unit("km") \
        vbu(v)_0 &= vecrow(num(res("02a", "v0_x")), num(res("02a", "v0_y")), num(res("02a", "v0_z"))) space unit("km/s")
    $

    #figure(
        image("../outputs/figures/s02a.png", width: 80%),
        caption: [Change in the osculating elements from Cowell's method with $J_2$.],
    ) <fig:s02a>

    The node regresses and the perigee advances, each at a steady rate with a small ripple every orbit, while $h$, $e$, and $i$ only oscillate. After #qty(48, "h"):
    $
        Delta Omega = qty(res("02a", "dOmega"), "deg"), quad Delta omega = qty(res("02a", "domega"), "deg") quad qed
    $
    Least-squares slopes give $dot(Omega) = qty(res("02a", "Omega_rate"), "deg/h")$ and $dot(omega) = qty(res("02a", "omega_rate"), "deg/h")$, matching Curtis's #qty(-0.172, "deg/h") and #qty(0.282, "deg/h").
<hwk:s02a>

+
    The Gauss variational equations are:
    #show math.equation: set block(breakable: true)
    $
        dv(h, t) &= -3/2 (J_2 mu R^2)/r^3 sin^2(i) sin(2u) \
        dv(e, t) &= 3/2 (J_2 mu R^2)/(h r^3) {h^2/(mu r) sin(theta) (3 sin^2(i) sin^2(u) - 1) - sin(2 u) sin^2(i) [(2 + e cos(theta)) cos(theta) + e]} \
        dv(theta, t) &=
        h/r^2 + 3/2 (J_2 mu R^2)/(e h r^3) [h^2/(mu r) cos(theta) (3 sin^2(i) sin^2(u) - 1) + (2 + e cos(theta)) sin(2 u) sin^2(i) sin(theta)] \
        dv(Omega, t) &= -3 (J_2 mu R^2)/(h r^3) sin^2(u) cos(i) \
        dv(i, t) &= -3/4 (J_2 mu R^2)/(h r^3) sin(2 u) sin(2 i) \
        dv(omega, t) &=
        3/2 (J_2 mu R^2)/(e h r^3) [h^2/(mu r) cos(theta) (1 - 3 sin^2(i) sin^2(u)) - (2 + e cos(theta)) sin(2 u) sin^2(i) sin(theta) + 2 e cos^2(i) sin^2(u)]
    $
    where $R$ is the earth's radius and $u = omega + theta$. Curtis prints Eq. 10.89b with $(3 + e cos theta)$. Substituting Eq. 10.88 into Eq. 10.84b gives $(2 + e cos theta)$, which Curtis's own `Example_10_06.m` (App. D.42) also uses, so that is the form above. SciPy's DOP853 integrator (relative tolerance $10^(-12)$) advances $vecrow(h, e, theta, Omega, i, omega)$ from the elements of Part A, sampled at the same 1001 times.

    #figure(
        image("../outputs/figures/s02b.png", width: 80%),
        caption: [Change in the osculating elements from Gauss' variational equations (Curtis Eq. 10.89) and from Cowell's method (Part A). Compare with Curtis Fig. 10.13.],
    ) <fig:s02b>

    The two solutions overlap, and the results reproduce Curtis Fig. 10.13. After #qty(48, "h"):
    $
        Delta Omega = qty(res("02b", "dOmega"), "deg"), quad Delta omega = qty(res("02b", "domega"), "deg") quad qed
    $
    The slopes are $dot(Omega) = qty(res("02b", "Omega_rate"), "deg/h")$ and $dot(omega) = qty(res("02b", "omega_rate"), "deg/h")$, while $h$, $e$, and $i$ only oscillate, as in Part A. Over the #qty(48, "h"), Gauss' equations and Cowell's method differ by at most #qty(res("02b", "diff_Omega"), "arcsecond") in $Omega$, #qty(res("02b", "diff_omega"), "arcsecond") in $omega$, #qty(res("02b", "diff_i"), "arcsecond") in $i$, #qty(res("02b", "diff_h"), "km^2/s") in $h$, and #num(res("02b", "diff_e")) in $e$. Both methods are exact for the same force, so these differences are integration error.
<hwk:s02b>

+
    The Lagrange planetary equations are:
    $
        dv(a, t) &= - (2 a^2)/mu pdv(R, t_p)\
        dv(e, t) &= - sqrt(1 - e^2)/(sqrt(mu a) e) pdv(R, omega) - (a (1 - e^2))/(mu e) pdv(R, t_p) \
        dv(t_p, t) &= (2 a^2)/mu pdv(R, a) + (a (1 - e^2))/(mu e) pdv(R, e) \
        dv(Omega, t) &= 1/(sqrt(mu a (1 - e^2)) sin(i)) pdv(R, i) \
        dv(i, t) &= 1/sqrt(mu a (1 - e^2)) (1/tan(i) pdv(R, omega) - 1/sin(i) pdv(R, Omega)) \
        dv(omega, t) &= - 1/(sqrt(mu a (1 - e^2)) tan(i)) pdv(R, i) + sqrt(1 - e^2)/(sqrt(mu a) e) pdv(R, e)
    $
    Here $R$ is the disturbing function, with $vbu(p) = grad R$, and the earth's radius is written $R_E$. Curtis prints Eqs. 10.50b and 10.50f with $sqrt(mu a e)$ in the denominator. The correct factor is $sqrt(mu a) thin e$, which is dimensionally consistent and gives the standard $J_2$ rates below.

    #emph[Disturbing function.] The $J_2$ potential of Curtis Eq. 10.24 is $Phi = J_2/2 mu/r (R_E/r)^2 (3 cos^2 phi - 1)$, with $vbu(p) = -grad Phi$, so $R = -Phi$. The latitude $delta$ satisfies $sin delta = cos phi = sin i sin u$, so:
    $
        R = (J_2 mu R_E^2)/(2 r^3) (1 - 3 sin^2 i sin^2 u)
    $
    This $R$ varies around the orbit, but its secular effect comes from its average over one orbit (time, or mean anomaly). With $expval(1 \/ r^3) = 1 \/ [a^3 (1 - e^2)^(3\/2)]$ and $expval(sin^2 u \/ r^3) = 1 \/ [2 a^3 (1 - e^2)^(3\/2)]$:
    $
        macron(R) = (mu J_2 R_E^2)/(4 a^3 (1 - e^2)^(3\/2)) (2 - 3 sin^2 i)
    $
    $macron(R)$ depends only on $a$, $e$, and $i$, so $pdv(macron(R), t_p) = pdv(macron(R), Omega) = pdv(macron(R), omega) = 0$, and:
    $
        pdv(macron(R), a) = -(3 macron(R))/a, quad pdv(macron(R), e) = (3 e macron(R))/(1 - e^2), quad pdv(macron(R), i) = -(3 mu J_2 R_E^2 sin i cos i)/(2 a^3 (1 - e^2)^(3\/2))
    $
    Substituting into the Lagrange planetary equations, with $n = sqrt(mu \/ a^3)$ and $p = a (1 - e^2)$:
    $
        dv(a, t) &= dv(e, t) = dv(i, t) = 0 \
        dv(Omega, t) &= -3/2 n J_2 (R_E/p)^2 cos i \
        dv(omega, t) &= 3/4 n J_2 (R_E/p)^2 (4 - 5 sin^2 i) \
        dv(t_p, t) &= -(3 a macron(R))/mu = -3/4 J_2 (R_E/p)^2 sqrt(1 - e^2) (2 - 3 sin^2 i)
    $
    For this orbit, $n = qty(res("02c", "n0"), "rad/s")$, $macron(R) = qty(res("02c", "R"), "km^2/s^2")$, $pdv(macron(R), a) = qty(res("02c", "dR_da"), "km/s^2")$, $pdv(macron(R), e) = qty(res("02c", "dR_de"), "km^2/s^2")$, and $pdv(macron(R), i) = qty(res("02c", "dR_di"), "km^2/s^2")$ (per radian). The rates of change of the elements are:
    $
        dv(a, t) &= dv(e, t) = dv(i, t) = 0 \
        dv(Omega, t) &= qty(res("02c", "Omega_rate_rad"), "rad/s") = qty(res("02c", "Omega_rate"), "deg/h") \
        dv(omega, t) &= qty(res("02c", "omega_rate_rad"), "rad/s") = qty(res("02c", "omega_rate"), "deg/h") \
        dv(t_p, t) &= num(res("02c", "tp_rate")) quad qed
    $
    These match the slopes from Parts A and B (#qty(res("02a", "Omega_rate"), "deg/h") and #qty(res("02a", "omega_rate"), "deg/h")) and Curtis's #qty(-0.172, "deg/h") and #qty(0.282, "deg/h"). Over #qty(48, "h") they give $Delta Omega = qty(res("02c", "Omega_48h"), "deg")$ and $Delta omega = qty(res("02c", "omega_48h"), "deg")$, within a few hundredths of a degree of Parts A and B; the rest is the short-period ripple. The zero rates of $a$, $e$, and $i$ say $J_2$ causes no secular change in the size, shape, or tilt of the orbit, only the periodic variations of Parts A and B, which averaging removes. Since $dot(t)_p < 0$, the perigee passages come earlier: the mean anomaly $M = n (t - t_p)$ runs faster than $n$ by $-n dot(t)_p = qty(res("02c", "M_rate"), "deg/h")$.
<hwk:s02c>

+
    The area, mass, and $C_D$ in Example 10.1 are:
    $
        & "Diameter:"         &   quad d & = #qty(1, "m") \
        & "Mass:"             &   quad m & = #qty(100, "kg") \
        & "Drag coefficient:" & quad C_D & = 2.2
    $
    so $B = C_D A \/ m = qty(res("01a", "B"), "m^2/kg")$, as in Problem 1, Part A. Gauss' equations are linear in the perturbing acceleration, so the rates of Eq. 10.89 ($J_2$) and Eq. 10.87 (drag, air at rest) add, with the two-body term $h \/ r^2$ in $dot(theta)$ counted once. The density is the USSA76 model of Problem 1, Part A, which gives $qty(res("02d", "rho_p"), "kg/m^3")$ at the #qty(300, "km") perigee and zero above #qty(1000, "km"). The initial elements and integrator are those of Part B.

    #figure(
        image("../outputs/figures/s02d.png", width: 90%),
        caption: [Left: change in the osculating elements with $J_2$ and drag (Gauss' equations), with Cowell's method for $J_2$ alone (Part A). Right: the effect of drag, $J_2$ and drag minus $J_2$ alone (Part B).],
    ) <fig:s02d>

    On the scale of the $J_2$ effects, the $J_2$-plus-drag solution is indistinguishable from Part A. The effect of drag is the difference from Part B. After #qty(48, "h"):
    $
        delta h = qty(res("02d", "dh"), "km^2/s"), quad delta e = num(res("02d", "de")), quad delta a = qty(res("02d", "da"), "km"), quad delta z_a = qty(res("02d", "dalta"), "km"), quad delta z_p = qty(res("02d", "daltp"), "km") quad qed
    $
    where $z_a$ and $z_p$ are the apogee and perigee altitudes.

    - #emph[Drag is secular:] Each perigee pass removes energy and angular momentum, so $h$, $a$, and $e$ fall in a step once per orbit. The apogee drops while the perigee barely moves, so drag circularizes the orbit, as in Problem 1. $J_2$, by contrast, only makes $h$, $e$, and $i$ oscillate (by #qty(res("02d", "h_range"), "km^2/s") peak to peak in $h$). The drag change in $h$ is already about 6% of that range after #qty(48, "h"), and it keeps growing.
    - #emph[Drag barely touches the orientation:] Eq. 10.87 has $dot(Omega) = dot(dotless.i) = 0$, and its $dot(omega)$ term changes sign with $sin theta$, so it nearly cancels over each orbit. The differences in $Omega$, $omega$, and $i$ (at most #qty(res("02d", "max_dOmega"), "arcsecond"), #qty(res("02d", "max_domega"), "arcsecond"), and #qty(res("02d", "max_di"), "arcsecond")) are indirect. Drag shortens the period, which shifts the phase of $J_2$'s short-period terms. A smaller $a$ also speeds up the secular $J_2$ rates slightly (they scale as $a^(-7\/2)$).
    - Over two days the effect of drag is small, but it is the only one of the two forces that changes the size and shape of the orbit secularly, so over a long enough time it dominates and the orbit decays as in Problem 1.
<hwk:s02d>

#pagebreak(weak: true)

== Code

#codly(header: [./src/index.py])
#raw(read("../src/index.py"), block: true, lang: "python") <code:index.py>
