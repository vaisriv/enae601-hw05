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
    See Example 10.1 on page 486 for the orbit. // FIXME: retype/restate orbit model here
    You may use any atmospheric density model you want, but use the same one across all parts.

    + Propagate this orbit numerically until it decays. Plot the altitude with time.
        #emph[(3 pts)]
    <hwk:p01a>

    + Use the Gauss variational equations (Curtis eq. 10.87) to do the same calculation.
        #emph[(3 pts)]
    <hwk:p01b>

    + Integrate including atmospheric rotation and zonal coefficients per Chao and Platt's. See Section 3.6 of #link("https://umaryland.on.worldcat.org/oclc/1112606368")[Chao & Hoots "Applied Orbit Perturbation and Maintenance" (2018, 2nd. Edition)].
        #emph[(4 pts)]

        #emph[#smallcaps[Note:] Even though this link is to the second edition, when you select "View eBook", it brings you to the first edition. You will need to click on the title, then "see other editions", then select the second edition.]
    <hwk:p01c>

    + Plot all three on the same graph and interpret the results.
        #emph[(2 pts)]
    <hwk:p01d>
] <hwk:p01>

+ Answer
<hwk:s01a>

+ Answer
<hwk:s01b>

+ Answer
<hwk:s01c>

+ Answer
<hwk:s01d>

#pagebreak(weak: true)

#prob(title: [$J_2$ effects #emph[(15 pts)]])[
    See Example 10.2 on page 492 for orbit information. // FIXME: retype/restate orbit model here
    However, do #emph[not] use Encke's method.

    + Integrate the orbit with the two-body force and $J_2$ perturbing force with ordinary numerical integration (not Encke's method).
        #emph[(2 pts)]
    <hwk:p02a>

    + Use the Gauss variational equations (Curtis eq. 10.89); see Example 10.6, Page 511. Plot the elements along with the computations from #link(<hwk:p02a>)[Part A]; your result should look something like Figure 10.13.
        #emph[(3 pts)]
    <hwk:p02b>

    + Using the Lagrange planetary equations (Curtis eq. 10.50), compute the time rate of change of the elements.
        #emph[(5 pts)]
    <hwk:p02c>

    + Using the Gauss equations once again, combine the $J_2$ and atmospheric drag forces and plot together with the result of #link(<hwk:p02a>)[Part A]. Assume the same area, mass, and $C_D$ as in Example 10.1. Interpret the results. What is the effect of the drag force?
        #emph[(5 pts)]
    <hwk:p02d>
] <hwk:p02>

+ Answer
<hwk:s02a>

+ Answer
<hwk:s02b>

+ Answer
<hwk:s02c>

+ Answer
<hwk:s02d>

#pagebreak(weak: true)

== Code

#codly(header: [./src/index.py])
#raw(read("../src/index.py"), block: true, lang: "python") <code:index.py>
