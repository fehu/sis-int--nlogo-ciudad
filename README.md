Traffic in a City
=================
_(El primer parcial de Sistemas Inteligentes)_

---

The environment represents city streets. 
Car-representing _turtles_ move on those streets, respecting traffic rules.

---

[Running Simulation](RunningSimulation.md).

The simulation can be found in [city.nlogo](src/city.nlogo).



City Structure
--------------

Each _patch_ should define '*is-road*' attribute.

The city consists of **roads** and **crosses**, that form **streets** and **avenues**.
Each road defines '*is-cross*' attribute.

A **road** (that is not a cross) has the following attributes:
* **road-name**
* *road-short-name*
* **road-lane**
* *road-direction*

The '*road-name*' and '*road-lane*' attributes together form the road's *unique identifier*.

A **cross** has the following attributes:
* *road-name-v*
* *road-lane-v*
* *road-name-h*
* *road-lane-h*

#### Registries

All the **roads** are registered in '*roads-info*' global variable. 
(see [city-roads-info.nls](src/city-roads-info.nls))

All the **crosses** (with semafors) are registered in '*crosses-info*'.
(see [city-roads-info.nls](src/city-crosses.nls))

#### Semafors

The semafors are represented by _turtles_ of breed '*semafor*'.

Each **streets cross** (consists of various **cross** patches) has exactly one semafor, 
that opens the traffic *horizontally* or *vertically*.

A semafor has the following attributes:
* *semafor-crosses*
* *green-direction*


City Generation
---------------

The city is build by a single *city-builder* turtle.

When building a **road**, the builder sets it's *road-direction* equal to own *heading*.

The city generation is done in several steps:

1. Build 4 *perimeter* streets.
2. Build streets grid:
   * selects a random block width (configurable);
   * (**!**) **if** the block breaks none of the *max-distance-between-streets-* constraints, jumps ahead;
   * builds a perpendicular street towards the center, until reaches the other side of the perimeter;
   * repeats the previous steps, until the (**!**) breaks.
3. Build **avenues** - two-directional streets. The selection is based upon *roads-info* registry (configurable).
4. Build semafors on the grouped **crosses**. Include the semafors into the *crosses-info* registry.
5. Kill the *city-builder*.


City Operation
--------------

The **cars** must move one patch every time that exists a movement, permitted by the *traffic rules*.

#### Cars Creation

The new **cars** are initially placed in the begining of the streets, after what they jump ahead a random distance.

#### Semafors Operation

The semafors change the open direction every given *ticks*. Currently they do so all at once.

#### Traffic Rules

![car-logic-design](http://fehu.github.io/sis-int--nlogo-ciudad/car-logic-design.png)

![permitted-moves](http://fehu.github.io/sis-int--nlogo-ciudad/permitted-moves.png)
