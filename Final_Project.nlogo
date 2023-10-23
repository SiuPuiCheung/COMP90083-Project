;; Student name: Siu Pui Cheung
;; Student ID: 1230798

globals
[
  total-satisfaction

  nb-angry-customer
  tot-angry-customer-leave
  avg-checkout-time
  current-nb-cashier
  current-nb-kitchen
  current-nb-delivery
  cashier-idx
  kitchen-idx
  delivery-idx
  meal-on-shelf
  leave
  satisfied-leave
  neutral-leave
  unsatisfied-leave
  no-meal-leave



]

breed [ customers customer ]
breed [ staffs staff ]


customers-own
[
 get-order? ;; If true, the customer have gotten the order
 get-meal?  ;; If true, the customer have gotten the meal
 get-ticket? ;; if true, the customer has gotten the ticket
 satisfaction ;; the customer's satisfaction rate
 stopping     ;; the time stop moving
 queueing?    ;; whehter customer is queueing
 queueing2?  ;; whether customer is queueing the delivery line
 select-queue ;; the chosen queue
 purchase-time ;; the whole purchase time
 queueing1-time ;; the first queueing time
 queueing2-time ;; the second queueing time

]
staffs-own
[
  cashier?  ;; If true, the staff is in charge of cashier
  delivery? ;; if true, the staff is in charge of delivering meal
  kitchen?  ;; If true, the staff is in charge of cooking
  do-order? ;; if true, the staff is ordering
  do-meal?  ;; if true, the staff is making meal
  do-delivery? ;; if true, the staff is delivering meal
  hold-meal?  ;; if true, the staff is holding meal
  back-work?  ;; if true, the staff is going back to work place from storage shelf

  order-time  ;; the taken ordering time
  meal-time   ;; the taken making meal time
  extra-time  ;; parameter for  extra working time for staff


]



;;  This procedure sets up the patches and turtles
to setup
  ;;  Clear everything.
  clear-all

  ;; set up restaurant layout
  ;; divide customer and staff zones
  ask patches with [ pycor = 0 ] [ set pcolor white ]
  ;; entrance doors
  ask patches with [ pxcor > -6 and pxcor < 6 and pycor = -20 ] [ set pcolor yellow ]
  ;; staff zone
  ask patches with [ pycor > 0 ] [ set pcolor grey ]
  ;; stoves
  ask patches with [ pxcor > -10 and pxcor < 10 and pycor = 20 ] [ set pcolor orange ]
  ;; shelf to store food
  ask patches with [ pycor = 10 ] [ set pcolor brown ]
  ;; checkout (closed)
  ask patches with [ pycor = 0 and (pxcor = -16 or pxcor = -8 or pxcor = 0
  or pxcor = 8 or pxcor = 15) ] [ set pcolor red ]
  set meal-on-shelf 0
  setup-staff
  reset-ticks
end

to go
  if ticks >=  1800 [ stop ]
  add-customer
  move-customer
  move-kitchen
  ifelse queueing-system = 1 ; different queueing-system has different prcoesses
  [move-cashier-1]
  [move-cashier-2
   move-delivery]


  tick
end

;; staff part
; setup staff positions and their properties
to setup-staff
  create-staffs nb-staff
  [
    set shape "person"
    set color blue
    set size 2
    set cashier? false
    set kitchen? false
    set delivery? false
    set back-work? false
    set hold-meal? false
    set do-order? false
    set do-delivery? false
    set order-time 0
    set meal-time 0

    set extra-time one-of (range 0 10)

    ; work place x coordinates
    let cashier-coor [15 8 0 -8 -16]
    let kitchen-coor (range 9 -9 -1)
    let delivery-coor [16 9 1 -7 -15]
    ; set staff positions in different order process
    let deliver-staff 1
    let nb-cashier wanted-cashier-nb
    let nb-delivery 1
    let nb-kitchen 1
    ; calcuate the number of different positions
    if queueing-system = 1
    [ ifelse nb-staff - nb-cashier < 1
        [set nb-cashier nb-staff - 1
        set nb-kitchen 1]
      [set nb-kitchen nb-staff - nb-cashier]]

    if queueing-system = 2
    [ ifelse nb-staff - (nb-cashier * 2) <= 1
      [set nb-cashier  nb-staff / 2 - 1
       set nb-delivery  nb-cashier
       set nb-kitchen (nb-staff - nb-cashier - nb-delivery)]
       [
       set nb-delivery  nb-cashier
        set nb-kitchen (nb-staff - nb-cashier - nb-delivery)] ]

     ; set staff being cashier
     if current-nb-cashier < nb-cashier
      [ set cashier? true
        set current-nb-cashier current-nb-cashier + 1
        setxy item cashier-idx cashier-coor 2
        ask patches with [ pxcor = item cashier-idx cashier-coor and pycor = 0] [ set pcolor green ]
        set cashier-idx cashier-idx + 1 ]

    if queueing-system = 2
    [
    ; set staff being delivery
      if cashier? = false and kitchen? = false and delivery-idx  < nb-delivery
    [ set delivery? true
      set current-nb-delivery current-nb-delivery + 1
      setxy item delivery-idx delivery-coor 2
      set delivery-idx delivery-idx + 1] ]
    ; set staff being kitchen
    if cashier? = false and delivery? = false
    [ set kitchen? true
      set current-nb-kitchen current-nb-kitchen + 1
      setxy item kitchen-idx kitchen-coor 19
      set kitchen-idx kitchen-idx + 1
    ]
  ]
end

; cashier movement
to move-cashier-1
  ask staffs with [cashier?][
    let cust-y ycor - 3
    let cust-x xcor
    ; accept order
    if any? customers-on patch cust-x (cust-y) = true [
      ask customers with [pxcor = cust-x and pycor = (cust-y) and get-order? = false] [ set get-order? true ]
      if order-time < 10 + extra-time
      [set order-time order-time + 1
       set do-order? true]
      ; complete the whole order
      if do-order? and hold-meal?
      [
        ask customers with [pxcor = cust-x and pycor = (cust-y) and get-order? = true]
        [ set get-order? false
          set get-meal? true
          set queueing? false]
        set hold-meal? false
        set do-order? false
      ]
    ]
     ; walk to shelf when taking order
     if order-time = 10 + extra-time and back-work? = false and do-order?
       [facexy xcor 10
         fd 1]
    ; take meal
    if ycor = 10 and do-order? and hold-meal? = false and meal-on-shelf > 0
      [set hold-meal? true
       set meal-on-shelf meal-on-shelf - 1
       set back-work? true]
    ; back to cahsier when collected meal
    if ycor != 2 and hold-meal? and back-work?
      [facexy xcor 2
       fd 1 ]

    if ycor = 2 and back-work?
      [ set back-work? false
        set order-time  0]
  ]
end

to move-cashier-2
   ask staffs with [cashier?][
    let cust-y ycor - 3
    let cust-x xcor
    if any? customers-on patch xcor (cust-y) = true  and count customers with [pxcor = cust-x + 1] < 5[
       ask customers with [pxcor = cust-x  and pycor = (cust-y) and get-order? = false] [ set get-order? true ]
       set do-order? true
       if order-time < 10 + extra-time
         [set order-time order-time + 1]]

    if count customers with [pxcor = cust-x  and pycor = (cust-y) and get-order? = true] = 1 and order-time  = 5 + extra-time
       [ask customers with [pxcor = cust-x  and pycor = (cust-y) and get-order? = true]
          [ set get-order? false
            set get-ticket? true
          ]
        set do-order? false
        set order-time 0
    ]
  ]
end

to move-delivery
  ask staffs with [delivery?][
    let cust-y ycor - 3
    let cust-x xcor
    let cashier-x xcor - 1
    if count staffs with [pxcor = cashier-x and pycor = ycor and order-time = 4] = 1 or count customers with [pxcor = cust-x and pycor = cust-y] = 1
       [set do-delivery? true]
    ; to collect meal
    if do-delivery? and back-work? = false and hold-meal? = false
      [facexy xcor 10
       fd 1]
    ; collect meal
    if ycor = 10 and do-delivery? and hold-meal? = false and meal-on-shelf > 0
    [set hold-meal? true
       set meal-on-shelf meal-on-shelf - 1
       set back-work? true]
    ; back to work place
    if ycor != 2 and hold-meal? and back-work?
      [facexy xcor 2
       fd 1 ]
    ; complete the whole order
    if ycor = 2 and back-work? and count customers with [pxcor = cust-x and pycor = cust-y and get-meal? = false] = 1
      [ ask customers with [pxcor = cust-x and pycor = cust-y and get-meal? = false]
        [set get-meal? true
        set queueing? false
        set queueing2? false]
        set back-work? false
        set hold-meal? false
        set do-delivery? false
        ] ]
end

; kitchen staff movement
to move-kitchen
  ; make meal
  ask staffs with [kitchen?][
   if meal-time < (12 + extra-time ) and meal-on-shelf < count customers * 1.2 ; make meal only when the storage is less than 1.2 times of the number of customers
    [set meal-time meal-time + 1]
    ; bring meal to the shelf
    if meal-time = (12 + extra-time ) and back-work? = false
    [set hold-meal? true
     facexy xcor 10
     fd 1]
    ; put down the meal
    if ycor = 10 and hold-meal?
    [set meal-on-shelf meal-on-shelf + 1
     set hold-meal? false
     set back-work? true]
   ; go back to stove
   if ycor != 19 and hold-meal? = false and back-work?
    [facexy xcor 19
    fd 1 ]
    ; reset and make ready to make meal
    if ycor = 19 and back-work? [
      set back-work? false
      set meal-time 0] ]
end



;; customer part
; set up customer
to add-customer
  ; add customer with random entrance speed when the current customer are feweer than the max threshold
  if count customers < max-customer-nb
  [ create-customers  random max-entrance-speed
    ; setup new customers
    [set shape "face happy"
      set size 1.5
      set color one-of remove red base-colors
      set satisfaction (random 20) + 80 ; random satisfaction at the beginning
      set get-order? false
      set get-meal? false
      set stopping 0
      setxy one-of (range -5 5) -20 ; enter from the door
      set select-queue "None"
      set purchase-time 0
      set queueing? false
      set queueing2? false
      set get-ticket? false ]]
end

; choose the cashier with the shortest queue
to select-cashier
  let min-cust 9999
  let selection 0

    if select-queue = "None"[
    ask patches with [pcolor = green] [
        let nb 100
        let x pxcor
        set nb count customers with [select-queue = x]
        if nb < min-cust [
          set min-cust nb
          set selection pxcor
        ]
      ]
    set select-queue selection]


end
; walk towards the selected cashier queue
to heading-cashier
  if queueing? = false and queueing2? = false

   [facexy select-queue  -15
      fd 1
    set purchase-time purchase-time + 1]

end
; enter the queue
to enter-queue
  if distance patch select-queue -15 < 1 and queueing? = false and queueing2? = false[
    set purchase-time purchase-time + 1
    setxy select-queue -16
    set queueing? true ]
end
; move a step if the front is empty until reach the cashier
to move-in-queue
   if queueing? = true and ycor < -2
  [  if any? customers-on patch xcor (ycor + 1.5)  = false[
    set purchase-time purchase-time + 1
    setxy   xcor  ( ycor + 1.5)] ]
end

;; same prcoess for the delivery line
to heading-queue2

   if xcor + 1 = select-queue + 1 [
      set purchase-time purchase-time + 1
      ifelse any? customers-on patch (select-queue + 1) ycor = false
      [facexy select-queue + 1 ycor
       fd 1

       set queueing2? true
       set queueing? false]
      [setxy select-queue + 1 ycor - 1.5
      ]]

end

to enter-queue2

  if queueing2? = false
  [set purchase-time purchase-time + 1
    ifelse any? other customers-here
      [if ycor >= -15
      [setxy xcor  ycor - 1.5]]
    [ set queueing2? true
      set queueing? false]]
end

to move-in-queue2
  if queueing2? = true and ycor < -2
  [ set purchase-time purchase-time + 1
    if any? customers-on patch xcor (ycor + 1.5)  = false[
    setxy   xcor  ( ycor + 1.5)] ]
end



to move-to-door
  facexy 0 -20
  fd 1

  if distance patch 0 -20 < 1
  [
    ifelse get-meal? = false
      [ set no-meal-leave no-meal-leave + 1  ]
      [ ifelse satisfaction >= 60 [set satisfied-leave satisfied-leave + 1 ]
        [ifelse satisfaction > 20 [set neutral-leave neutral-leave + 1 ]
        [set unsatisfied-leave unsatisfied-leave + 1 ] ] ]
  set leave leave + 1
  die
  ]
end


to move-customer
  ask customers [

   ifelse  get-meal? or (satisfaction < 20 and get-order? = false and get-ticket? = false); leave restaurant when having meal or when satisfaction is under 20
    [move-to-door]
    [if satisfaction > 20 [set satisfaction satisfaction - 0.25]
      if queueing? [ set queueing1-time queueing1-time + 1 ]
      if queueing2? [ set queueing2-time queueing2-time + 1]
    select-cashier
    heading-cashier
    enter-queue
    move-in-queue
    if queueing-system = 2 and get-ticket?[
     heading-queue2
     enter-queue2
     move-in-queue2
     ]
    ]
  ; different shape depending on the satisfaction
  if satisfaction >= 30 and satisfaction < 60 [set shape "face neutral"]
  if satisfaction < 30
    [set shape "face sad"
      ask customers-on neighbors  [set satisfaction satisfaction - 0.1]] ; 'sad face' customer affect neighbour customers dissatisfaction
   if satisfaction < 20 and get-meal? = false [ set color red ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
1037
10
1474
552
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-20
20
1
1
1
ticks
30.0

BUTTON
41
25
104
58
Setup
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
131
25
194
58
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
32
106
204
139
nb-staff
nb-staff
3
20
15.0
1
1
NIL
HORIZONTAL

CHOOSER
33
193
125
238
queueing-system
queueing-system
1 2
1

MONITOR
33
301
136
346
Cashier-Kitchen ratio
count staffs with [cashier?] / count staffs with [kitchen?]
2
1
11

MONITOR
141
249
277
294
Cashier / Delivery proportion
count staffs with [cashier?] / nb-staff
2
1
11

SLIDER
33
393
205
426
max-customer-nb
max-customer-nb
1
50
50.0
1
1
NIL
HORIZONTAL

SLIDER
33
437
205
470
max-entrance-speed
max-entrance-speed
0
20
15.0
1
1
NIL
HORIZONTAL

SLIDER
32
150
204
183
wanted-cashier-nb
wanted-cashier-nb
1
5
5.0
1
1
NIL
HORIZONTAL

MONITOR
28
249
139
294
Kitchen staff proportion
count staffs with [kitchen?] / nb-staff
2
1
11

TEXTBOX
19
81
169
99
Staff setup
12
0.0
1

TEXTBOX
26
371
176
389
Customer setup
12
0.0
1

MONITOR
141
300
235
345
Opened counters
count staffs with [cashier?]
0
1
11

MONITOR
31
486
128
531
Customers numbers
count customers
0
1
11

MONITOR
144
200
230
245
Meals on shelf
meal-on-shelf
0
1
11

MONITOR
138
486
236
531
Queueing number
Count customers with [queueing?] + Count customers with [queueing2?]
0
1
11

PLOT
281
10
602
160
Customer numbers
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Customer nb" 1.0 0 -16777216 true "" "plot count customers"
"Queueing nb" 1.0 0 -955883 true "" "plot Count customers with [queueing?] + Count customers with [queueing2?]"
"Meal-shelf nb" 1.0 0 -13345367 true "" "plot meal-on-shelf"
"Unsatisfied nb" 1.0 0 -2674135 true "" "plot count customers with [shape = \"face sad\"]"

PLOT
281
160
602
310
Customer satisfaction proportion
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Satisfied" 1.0 0 -13840069 true "" "plot count customers with [shape = \"face happy\"] / count customers "
"Neutral" 1.0 0 -1184463 true "" "plot count customers with [shape = \"face neutral\"] / count customers "
"Unsatisfied" 1.0 0 -2674135 true "" "plot count customers with [shape = \"face sad\"] / count customers  "

PLOT
602
458
832
608
Meals on shelf-Customer ratio
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot meal-on-shelf / count customers"

PLOT
282
307
603
457
Leave with/no meal- leave proportion
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"With meal" 1.0 0 -13840069 true "" "plot (satisfied-leave + neutral-leave + unsatisfied-leave) / leave"
"Without meal" 1.0 0 -2674135 true "" "plot no-meal-leave / leave"

PLOT
603
309
832
459
Get meal queue - Order queue ratio
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count customers with [queueing2?] / count customers with [queueing?] "

PLOT
280
457
603
607
Sum of customer satisfaction leave proportion
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Satisfied" 1.0 0 -13840069 true "" "plot satisfied-leave / leave"
"Neutral" 1.0 0 -987046 true "" "plot neutral-leave / leave"
"Unsatisfied" 1.0 0 -2674135 true "" "plot unsatisfied-leave / leave"
"No-meal" 1.0 0 -7500403 true "" "plot no-meal-leave / leave"

PLOT
602
11
903
158
angry  with/no meal proportion
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Angry with meal" 1.0 0 -955883 true "" "plot count customers with [satisfaction < 20 and get-meal?] / count customers with [satisfaction < 20]"
"Angry without meal" 1.0 0 -2674135 true "plot count customers with [satisfaction < 20 and get-meal? = false ] / count customers with [satisfaction < 20]" "plot count customers with [satisfaction < 20 and get-meal? = false] / count customers with [satisfaction < 20]"

PLOT
601
158
901
308
Avg queueing time
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Queueing1" 1.0 0 -13345367 true "" "plot mean [queueing1-time] of customers with [get-meal? = false]"
"Queueing2" 1.0 0 -7500403 true "" "plot mean [queueing2-time] of customers with [get-meal? = false]"
"All-queueing" 1.0 0 -16777216 true "" "plot mean [queueing1-time] of customers with [get-meal? = false] + mean [queueing2-time] of customers with [get-meal? = false]\n"

PLOT
833
308
1033
458
Avg customer satisfaction
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [satisfaction] of customers"

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
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean [queueing1-time] of customers with [get-meal? = false] + mean [queueing2-time] of customers with [get-meal? = false]</metric>
    <enumeratedValueSet variable="order-process">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-staff">
      <value value="5"/>
      <value value="8"/>
      <value value="15"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wanted-cashier-nb">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-customer-nb">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-entrance-speed">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
