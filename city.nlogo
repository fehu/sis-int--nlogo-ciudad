
globals [ street-north-east-color   street-south-west-color   street-cross-color
          delta-street-distance-v   delta-street-distance-h
          last-road-name-v          last-road-name-h
          roads-info
  ]

breed [ road-builder road-builders ]

road-builder-own [ 
  last-turns
  known-street-distances-v
  known-street-distances-h
  ]

patches-own [ 
  is-road
  is-cross
  ; for roads
  road-direction
  road-name
  road-short-name
  ; for crosses
  open-direction
  road-name-v
  road-name-h
;  next-cross-distance-north
;  next-cross-distance-east
;  next-cross-distance-south
;  next-cross-distance-west
  ]

to setup
  setup-world
  
  setup-build

  create-road-builder 1
  ask road-builder[ set color white ]
end

to setup-world
  clear-all
  resize-world -100 100 -50 50
  set-patch-size 8

  ask patches [ set is-road false ]
end


to setup-build
  
  set delta-street-distance-v max-street-distance-v - min-street-distance-v
  assert delta-street-distance-v >= 0 "max-street-distance-v must be greater than min-street-distance-v"

  set delta-street-distance-h max-street-distance-h - min-street-distance-h
  assert delta-street-distance-h >= 0 "max-street-distance-h must be greater than min-street-distance-h"

  set street-north-east-color [189 183 107]
  set street-south-west-color [100 149 237]
  set street-cross-color      red

  set last-road-name-v 0
  set last-road-name-h 0

  set roads-info []
end



;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;;
;;
;; ROADS

to build-roads
  
  ask road-builder [ 
    
    build-perimeter 
    set last-turns []
    
    build-streets-grid
    
    ]
  
end

to build-perimeter'
  ask road-builder [ build-perimeter
                     set last-turns []
                   ]
end

to next-street'
  ask road-builder [ let x next-street ]
end

to build-streets-grid'
  ask road-builder [ build-streets-grid ]
end

;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; transforms some of the existing roads to two-lanes
to build-avenues
  let selected select-avenues
  let av-h first selected
  let av-v last  selected
  
  
  
end

to build-avenue [ inf ]
  set xcor    get-road-x inf
  set ycor    get-road-y inf
  set heading get-road-dir inf
  
  move task [ is-perimeter? patch-ahead 1 ] 
       task [ ]
  fd 1
  rt 90
  fd 1
  rt 90
  
  let name sentence get-road-name inf "'"
  let short sentence get-road-short-name inf "'"
    
  mem-road-here short name 0
  move-building-road name short
  
end

to-report select-avenues
  let av-h sort-by-prev-dist (filter [h-dir? get-road-dir ?1] roads-info)
  let av-v sort-by-prev-dist (filter [v-dir? get-road-dir ?1] roads-info)
                   
  let av-h-m sublist av-h 0 (length av-h / 3)
  let av-v-m sublist av-v 0 (length av-v / 3)
  
  report list av-h-m av-v-m
                   
end

to-report sort-by-prev-dist [ infs ]
  report sort-by [get-road-prev-dist ?1 > get-road-prev-dist ?2] infs
end



;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; builds a grid of one-lane streets
to build-streets-grid
  
  ; build vertical streets
  build-streets-grid-half
  ; build horizontal streets
  build-streets-grid-half
  
end

to build-streets-grid-half
  if next-street [ build-streets-grid-half ]
end


;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; builds the next street in a "snake" manner
to-report next-street
  let to-jump random-next-street-distance heading
  if to-jump < 0 [ error "not a n*pi/2 direction" ]
  
  let dp distance-to-perimeter
  if dp = -1 [ error "cannot handle angles different n*pi/2" ]
  
  
  ifelse to-jump > dp - min-street-distance heading
     [;THEN
       jump dp
       next-street-turn
       
       if first last-turns = "L" [ set last-turns ["L"] ]
       if first last-turns = "R" [ set last-turns ["R"] ]
       
       report false
      ]
     
     [;ELSE
       jump to-jump 
  
       let name next-street-name heading
       let short substring name 2 (length name)
  
       next-street-turn
       build-cross-here name
       mem-road-here short name to-jump
       
       if show-road-begin? [ ask patch-ahead -1 [ set plabel name ] ]
       
       move-building-road name short
       
       fd 1
       build-cross-here name
       next-street-turn
       
       report true
      ]
  
end

to move-building-road [ name short-name ]
  move task [ is-perimeter? patch-ahead 1 ]
       task [ 
              ifelse is-road? patch-here 
                    [ build-cross-here name ] 
                    [ build-road-here name short-name ]
         ]
end

to-report next-street-name [ dir ]
  if v-dir? dir [ set last-road-name-v last-road-name-v + 1 
                  report word "h-" last-road-name-v
                ]
  if h-dir? dir [ set last-road-name-h last-road-name-h + 1 
                  report word "v-" last-road-name-h
                ]
end

to-report random-next-street-distance [ dir ]
  report ifelse-value v-dir? dir
               [ min-street-distance-h + random delta-street-distance-h ][
         ifelse-value h-dir? dir
               [ min-street-distance-v + random delta-street-distance-v ]
               [ -1 ]
               ]
end


; next turn for snake-like turns (LLRRLLRRLL...)
to next-street-turn
  ifelse not empty? last-turns
        [ ifelse empty? but-first last-turns 
                [ if first last-turns = "L"
                     [ 
                       set last-turns ["L" "L"]
                       lt 90 
                       ]
                  if first last-turns = "R"
                     [ 
                       set last-turns ["R" "R"]
                       rt 90 
                       ]
                  ]
                [ let fst first last-turns
                  let snd first but-first last-turns
                  assert (fst = snd) "FAIL: *1"
                  
                  if fst = "L"
                     [ set last-turns ["R"]
                       rt 90
                        ]
                  if fst = "R"
                     [ set last-turns ["L"]
                       lt 90
                        ]
                   ]
          ]
        [ 
          ; initial turn: Left
          set last-turns ["L" "L"] 
          lt 90
          ]
  
end


;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; bulds road perimeter
to build-perimeter
  ; go to left-bottom corner (with margin 1)
  set xcor min-pxcor + perimeter-margin
  set ycor min-pycor + perimeter-margin

  set heading East ; random-choice (list North East)
  
  move task [ is-road? patch-ahead 1 ]
       task [ 
              let dir' dir2str heading-right
              let name word "Perimeter-" dir'
              let short first dir'
              
              build-road-here name short
              
              if is-edge? patch-ahead perimeter-margin
                 [ lt 90
                   build-cross-here name
                   mem-road-here name short 0
;                   lt 90 
                   ]
            ]
end




;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;;
;;
;; COMMON



;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; build different roads

to build-road-here [ name short-name ]
  set is-road   true
  set is-cross  false
  set pcolor    street-color-to-paint heading
  
  let p patch-ahead -1
;  let name ifelse-value is-cross? p
;   [road-name] of 
   
  set road-name name
  set road-short-name short-name
  
  if fill-street-name? [ set plabel short-name ]
end

to build-cross-here [ current-street ] ; case new street
  set is-road  true
  set is-cross true
  set pcolor   street-cross-color
  
  let perpend-street [road-name] of patch-right-and-ahead 90 1
  
  set road-name-v ifelse-value v-dir? heading
                        [ current-street ]
                        [ perpend-street ]
  set road-name-h ifelse-value h-dir? heading
                        [ current-street ]
                        [ perpend-street ]
  
  
end

to-report street-color-to-paint [ dir ]
  if dir = North or dir = East
     [ report street-north-east-color ]
  if dir = South or dir = West
     [ report street-south-west-color ]
  report []
end

;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; repeating tasks

to move [ until do ]
  fd 1
  run do

  if not (runresult until)
     [ move until do ]
end


;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; working with roads-info

to mem-road-here [ name short-name prev-dist ]
  let s-cor list pxcor pycor
  mem-road heading name short-name s-cor prev-dist
end

to mem-road [ dir name short-name start-cor prev-dist ]
  
  let info (list name dir start-cor prev-dist short-name)
  
  set roads-info fput info roads-info
end

to assert-info-length [ inf ]
  assert (length inf = 5) "not an info"
  assert (length item 2 inf = 2) "not a coordinate"
end

to-report get-road-name [ inf ]
  assert-info-length inf
  report first inf
end

to-report get-road-dir [ inf ]
  assert-info-length inf
  report item 1 inf
end

to-report get-road-cor [ inf ]
  assert-info-length inf
  report item 2 inf
end

to-report get-road-prev-dist [ inf ]
  assert-info-length inf
  report item 3 inf
end

to-report get-road-short-name [ inf ]
  assert-info-length inf
  report item 4 inf
end

to-report get-road-x [ inf ] 
  report item 0 get-road-cor inf
end

to-report get-road-y [ inf ] 
  report item 1 get-road-cor inf
end


;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; city orientation

to-report min-street-distance [ dir ]
  report ifelse-value v-dir? dir
               [ min-street-distance-h ][
         ifelse-value h-dir? dir
               [ min-street-distance-v  ]
               [ -1 ]
               ]
end

to-report distance-to-perimeter
  report simple-distance-to-edge - perimeter-margin
end

to-report simple-distance-to-edge
  report ifelse-value (heading = North)
               [ abs (max-pycor - pycor) ][
         ifelse-value (heading = East)
               [ abs (max-pxcor - pxcor) ][ 
         ifelse-value (heading = South)
               [ abs (min-pycor - pycor)  ][ 
         ifelse-value (heading = West)
               [ abs (min-pxcor - pxcor) ]
               [ -1 ]
                 ]]]
end

;to-report forall-patches-ahead dist [ cond ]
;  report ifelse cond
;end


;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; is-something?

to-report is-road? [ patch' ]
  report [is-road] of patch'
end

to-report is-cross? [ patch' ]
  report [is-road and is-cross] of patch'
end

to-report cross-here?
  report is-cross? patch-here
end

to-report is-edge? [ a ]
  report [pxcor] of a = max-pxcor or [pxcor] of a = min-pxcor or
         [pycor] of a = max-pycor or [pycor] of a = min-pycor
end

to-report is-perimeter? [ a ]
  report [pxcor] of a = max-pxcor - perimeter-margin or [pxcor] of a = min-pxcor + perimeter-margin or
         [pycor] of a = max-pycor - perimeter-margin or [pycor] of a = min-pycor + perimeter-margin
end

;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; controller scope

;to-report street-distances

;end

;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; directions

to-report North 
  report 0
end

to-report East
  report 90
end

to-report South
  report 180
end

to-report West
  report 270
end

; vertical direction?
to-report v-dir? [ d ]
  report (remainder d 180) = 0
end

to-report h-dir? [ d ]
  report (remainder d 90) = 0 and not v-dir? d
end

to-report dir2str [ dir ]
  report ifelse-value (dir = North)
               [ "North" ][
         ifelse-value (dir = East)
               [ "East" ][ 
         ifelse-value (dir = South)
               [ "South" ][ 
         ifelse-value (dir = West)
               [ "West" ]
               [ word dir " degrees" ]
                 ]]]
end

to-report heading-right
  let h heading + 90
  report ifelse-value (h = 360)
               [ 0 ]
               [ h ]
end

;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; ;; 
;; misc

to assert [b msg]
  if not b [ error msg ]
end

to-report random-choice [ l ]
  report first shuffle l
end
@#$#@#$#@
GRAPHICS-WINDOW
9
10
1627
849
100
50
8.0
1
10
1
1
1
0
1
1
1
-100
100
-50
50
0
0
1
ticks
30.0

BUTTON
1649
232
1722
265
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1726
233
1854
266
NIL
build-roads
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1646
56
1833
89
min-street-distance-v
min-street-distance-v
1
100
15
1
1
NIL
HORIZONTAL

SLIDER
1833
56
2022
89
max-street-distance-v
max-street-distance-v
1
100
40
1
1
NIL
HORIZONTAL

BUTTON
1755
339
1855
372
NIL
next-street'
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1645
104
1834
137
min-street-distance-h
min-street-distance-h
1
50
20
1
1
NIL
HORIZONTAL

SLIDER
1833
104
2025
137
max-street-distance-h
max-street-distance-h
1
50
30
1
1
NIL
HORIZONTAL

BUTTON
1714
381
1856
414
NIL
build-streets-grid'
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1723
300
1854
333
NIL
build-perimeter'
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1645
12
1817
45
perimeter-margin
perimeter-margin
1
10
2
1
1
NIL
HORIZONTAL

SWITCH
1824
157
1982
190
fill-street-name?
fill-street-name?
1
1
-1000

SWITCH
1645
157
1816
190
show-road-begin?
show-road-begin?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
