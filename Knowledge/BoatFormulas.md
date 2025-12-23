# Boat formulas

## General geometry
**Triangle area according to Heron**  
$A=\frac{\sqrt{(a+b+c)·(a+b-c)·(b+c-a)·(c+a-b)}}{16}$  

$A = \sqrt{s(s-a)(s-b)(s-c)} \qquad s = \frac{a+b+c}{2}$  

A = Area of the triangle [m²]  
s = Helping parameter  
a = Distance between point B and C [m]  
b = Distance between point A and C [m]  
c = Distance between point A and B [m]  
[[Wikipedia]](https://en.wikipedia.org/wiki/Heronian_triangle)

**Triangle area according to sin formula**  
$A = \frac{1}{2}·a·b·sin(\gamma)$  
A = Area of the triangle [m²]  
a = Distance between point B and C [m]  
b = Distance between point A and C [m]  
γ = Angle between CA and CB  

## Hydrostatic force
**Hydrostatic force on triangle**  
Force acting on the center of hydrostatic pressure against the normal direction  
$F_S=\rho·g·h·A$  
F<sub>S</sub> = Hydrostatic pressure force [N]  
ρ = Density of the fluid [kg/m³]  
g = Gravitational acceleration = 9.8m/s2 on earth  
h = Height of the center of pressure below the surface of the fluid [m]  
A = Area [m2]  

## Drag force
**General drag equation**  
$FD=frac{1}{2}·\rho·A·C_D·v2$  
F<sub>D</sub> = Drag force [N]  
ρ = Density of the fluid [kg/m³]  
A = Area [m²]  
CD = Drag coefficient [1]  
v = Velocity [m/s]  

**Reynolds number**  
$Re=\frac{v·L}{\nu}=\frac{\rho·v·L}{\mu}$  
Re = Reynolds number [1]  
v =Flow speed [m/s]  
L = Length of the body [m]  
ν = Kinematic viscosity of the fluid [m²/s]  
ρ = Density of the fluid [kg/m³]  
μ = Dynamic viscosity of the fluid [Pa·s] = [N·s/m2]  

**Frictional resistance coefficient**  
According to International Towing Tank Conference 1957  
$C_{DF}=\frac{0.075}{log_10(Re-2)^2}$  
C<sub>DF</sub> = Frictional drag coefficient [1]  
Re = Reynolds number [1]  
Sources:  
[[Viscous Water Resistance formula]](https://www.gamedeveloper.com/programming/water-interaction-model-for-boats-in-video-games-part-2)  
[[PDF from here]](https://repository.tudelft.nl/islandora/object/uuid%3A16d77473-7043-4099-a8c6-bf58f555e2e7)  
[[More advanced version]](https://www.mermaid-consultants.com/ship-frictional-resistance.html)  

**Simple pressure and suction force**  
$F_{PD} = \frac{1}{2} \cdot \rho \cdot C_{PD} \cdot S \cdot (v \cdot n)^2 \cdot \vec{n} \qquad \text{if } v \cdot n > 0$  
$F_{SD} = \frac{1}{2} \cdot \rho \cdot C_{SD} \cdot S \cdot (v \cdot n)^2 \cdot \vec{n} \cdot f_s \qquad \text{if } v \cdot n < 0$  

$F_{PD} / F_{SD}$ = Force vector acting along the face normal [N]  
ρ = Density of the fluid [kg/m³]  
$C_{PD}$ = Pressure drag coefficient (usually ~0.5 to 1.0) [1]  
$C_{SD}$ = Suction drag coefficient (usually ~0.05 to 0.1) [1]  
$S$ = Submerged area of the triangle [m²]  
$v \cdot n$ = The dot product of the velocity vector and the face normal [m/s]  
$\vec{n}$ = The unit normal vector of the face  
$f_s$ = Suction falloff (depth-based attenuation) [1] 

**Complex presssure drag force**  
$F_{DP}=(C_{DP1}·r_v+C_{DP2}·{r_v}^2)·S·cos(\theta)·f_p \qquad r_v=\frac{v_i}{v_r}$  
F<sub>DP</sub> = Pressure drag force if θ > 0 [N]  
C<sub>Dp1</sub> = Linear pressure drag coefficient [1]  
C<sub>DS2</sub> = Quadratic pressure drag coefficient [1]  
r<sub>v</sub> = Velocity ratio [1]  
S = Area [m2]  
θ = Angle between the velocity and the face normal [rad]  
f_P = Pressure falloff power [?]  
v<sub>i</sub> = Current velocity [1]  
v<sub>r</sub> = Reference velocity [1]  

**Complex suction drag force**  
$F_{DS}=(C_{DS1}·r_v+C_{DS2}·{r_v}^2)·S·cos(\theta)·f_s \qquad r_v=\frac{v_i}{v_r}$  
F<sub>DS</sub> = Suction drag force if θ > 0 [N]  
C<sub>DS1</sub> = Linear suction drag coefficient [1]  
C<sub>DS2</sub> = Quadratic suction drag coefficient [1]  
r<sub>v</sub> = Velocity ratio [1]  
S = Area [m2]  
θ = Angle between the velocity and the face normal [rad]  
f_S = Suction falloff power [?]  
v<sub>i</sub> = Current velocity [1]  
v<sub>r</sub> = Reference velocity [1]  
