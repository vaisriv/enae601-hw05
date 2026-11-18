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
    Answer
<hwk:s01a>

+
    The Gauss variational equations are:
    $
        dv(h, t) &= - B/2 h rho nu \
        dv(e, t) &= - B (e + cos(theta)) rho nu \
        dv(theta, t) &= h/r^2 + B (rho nu)/e sin(theta) \
        dv(Omega, t) &= 0 \
        dv(i, t) &= 0 \
        dv(omega, t) &= - B (rho nu)/e sin(theta)
    $

    Answer
<hwk:s01b>

+
    Answer
<hwk:s01c>

+
    Answer
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
    Answer
<hwk:s02a>

+
    The Gauss variational equations are:
    $
        dv(h, t) &= -3/2 (J_2 mu R^2)/r^3 sin^2(i) sin(2u) \
        dv(e, t) &= 3/2 (J_2 mu R^2)/(h r^3) {h^2/(mu r) sin(theta) (3 sin^2(i) sin^2(u) - 1) - sin(2 u) sin^2(i) [(3 + e cos(theta)) cos(theta) + e]} \
        dv(theta, t) &=
            h/r^2 + 3/2 (J_2 mu R^2)/(e h r^3) [h^2/(mu r) cos(theta) (3 sin^2(i) sin^2(u) - 1) + (2 + e cos(theta)) sin(2 u) sin^2(i) sin(theta)] \
        dv(Omega, t) &= -3 (J_2 mu R^2)/(h r^3) sin^2(u) cos(i) \
        dv(i, t) &= -3/4 (J_2 mu R^2)/(h r^3) sin(2 u) sin(2 i) \
        dv(omega, t) &=
            3/2 (J_2 mu R^2)/(e h r^3) [h^2/(mu r) cos(theta) (1 - 3 sin^2(i) sin^2(u)) - (2 + e cos(theta)) sin(2 u) sin^2(i) sin(theta) + 2 e cos^2(i) sin^2(u)]
    $
    Answer
<hwk:s02b>

+
    The Lagrange planetary equations are:
    $
        dv(a, t) &= - (2 a^2)/mu pdv(R, t_p)\
        dv(e, t) &= - sqrt(1 - e^2)/sqrt(mu a e) pdv(R, omega) - (a (1 - e^2))/(mu e) pdv(R, t_p) \
        dv(t_p, t) &= (2 a^2)/mu pdv(R, a) + (a (1 - e^2))/(mu e) pdv(R, e) \
        dv(Omega, t) &= 1/(sqrt(mu a (1 - e^2)) sin(i)) pdv(R, i) \
        dv(i, t) &= 1/sqrt(mu a (1 - e^2)) (1/tan(i) pdv(R, omega) - 1/sin(i) pdv(R, Omega)) \
        dv(omega, t) &= - 1/(sqrt(mu a (1 - e^2)) tan(i)) pdv(R, i) + sqrt(1 - e^2)/sqrt(mu a e) pdv(R, e)
    $
    Answer
<hwk:s02c>

+
    The area, mass, and $C_D$ in Example 10.1 are:
    $
        &"Diameter:" &quad d &= #qty(1, "m") \
        &"Mass:" &quad omega &= #qty(100, "kg") \
        &"Drag coefficient:" &quad C_D &= 2.2
    $
    Answer
<hwk:s02d>

#pagebreak(weak: true)

== Code

#codly(header: [./src/index.py])
#raw(read("../src/index.py"), block: true, lang: "python") <code:index.py>
