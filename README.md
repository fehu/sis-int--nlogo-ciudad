Traffic in a City
=================
_(El primer parcial de Sistemas Inteligentes)_

---

The environment represents city streets. 
Car-representing _turtles_ move on those streets, respecting traffic rules.

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

All the **crosses** (with semafors) are registered in '*crosses-info*'.

#### Semafors

The semafors are represented by _turtles_ of breed '*semafor*'.

Each **streets cross** (consists of various **cross** patches) has exactly one semafor, 
that opens the traffic *horizontally* or *vertically*.

A *semafor* has the following attributes:
* *semafor-crosses*
* *green-direction*


City Generation
---------------

The city is build by a single '*city-builder*' turtle.

1. 
