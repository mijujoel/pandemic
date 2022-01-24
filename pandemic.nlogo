;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DECLARATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
__includes [ "people.nls" "interact.nls" "health.nls" "environment.nls" "move.nls" "graphics.nls" "report.nls" "strategies.nls" ]

extensions [ vid ]        ;; movie

breed [ people person ]   ;; use people instead of turtles

globals [

  ;Counters and statistics for person-to-person contacts
  contacts                ;; total number of contacts made between people
  old-contacts            ;; previous total from earlier time period
  contacts-per-time       ;; tallies per unit of time
  starts-per-time         ;; how many contacts made this time period
  ends-per-time           ;; how many contacts ended

  ;Counters and statistics for interactions
  interaction-starts      ;; total number of interactions between people (i.e., you may/may not interact after contact
  old-interaction-starts  ;; previous total from earlier time period
  interaction-ends        ;; total number ended
  old-interaction-ends    ;; previous total
  active-interactions     ;; total number of interactions currently active

  ;counters and flags for infections
  initial-infecteds
  reinfectious

 ; Phase
  Phase
  phase-step
  phase-time

  ;External influence counters and statistics
  externals               ;; total number of external visits

  ;Color used to create background environment - i.e., impacts from environment not interactions
  env0-color
  env1-color
  env2-color

  ;seeds
  gseed                 ;seed used for go
  iseed                 ;seed used for initial

  ;time
  time-units
]

;Attributes for patches (other than Netlogo-defined attributes)
patches-own [
 intensity               ;; used to create degrees of influence (rather than a static background)
 original-color          ;; used in conjunction with external influence
]

;People have attributes
people-own [
  in-external?              ;; Keep track of whether individual is in external environment
  external-intensity-sum ;; Keep track of sum of all intensities person runs across while in environment
  external-intensity-avg ;; Used to determine probability of infection
  external-patch-count   ;; Number of patches visited in environment
  end-time               ;; when current interaction will end
  illness-time           ;; sickness time
  infectious-time        ;; infectious
  incubation-time        ;; time from exposed to infected
  initiator?             ;; keep track of who initiates the interaction (to keep model straight)
  interaction-length     ;; length of current interaction
  kind                   ;; 1 - 5 are "asymptomatic","mild","some symptoms","serious","severe"
  num-externals          ;; cumulative number of incursions into external environment
  num-interactions       ;; cumulative number of interactions
  partner                ;; The person that is our current partner in an interaction - self used in external case
  quarantine-time        ;; how long the stay in quarantine
  reinfection-flag?      ;; flag to indicate reinfection
  start-time             ;; when current interaction starts
  status                 ;; 0 for a healthy, 1 for susceptible, 2 for exposed, 3 for infectious, 4 for hospitalized, 5 for recovered, 6 for deceased, 7 for re-infected
  susceptibility         ;; general susceptibility to infection - can combine with kind to determine infection
  test-result?           ;; positive or negative
  total-external-time    ;; cumulative time spent in environment
  total-interact-time    ;; cumulative time spent in interactions
  vaccinated?            ;; received vaccination?
  memory                 ;; list of partners that can be used tracing interactions
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to startup

  clear-all                      ;clear everything at beginning, though setup can leave time series plot alone
  set Phases "Custom"            ;changes a bunch of parameters
  set Social-Interaction? TRUE   ;need Social Interaction or Environment on, but Environment not ready yet!
  set Environment? FALSE

end

to setup

  clear-most-things ;leaves summary plot so comparisons can be made

  if Social-Interaction? = FALSE and Environment?  = FALSE
  [
    print "Must execute Social-Interaction and/or Environment"
    stop
  ]

  if printing? [ output-print (word "0::::MODEL REPORT with printing:" printing? ":and verification:" verify?) ]
  ;;Check inputs
  let total-prob prob-asymptomatic + prob-mild-symptoms + prob-medium-symptoms + prob-serious-symptoms + prob-severe-symptoms
  if (total-prob != 100 )
  [
      print (word "Categories of people must sum to 100, but instead sum to " total-prob)
      stop
  ]

  set iseed seed-set setup-seed "model setup" ;sets the random number generator for setup

  setup-globals       ;initialize to 0
  setup-env           ;patches
  setup-people        ;individuals

  ;start graphics
  setup-histograms    ;initialize histogram
  update-plot-data
  update-histograms
  update-monitors

  set gseed seed-set go-seed "runtime"  ;sets the random number generator at runtime
  set time-units 0    ;can set up so events take multiple ticks, etc.

  reset-ticks

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-globals

  ;globals used for social interactions
  set contacts 0
  set old-contacts 0
  set contacts-per-time 0.0
  set starts-per-time 0
  set ends-per-time 0

  set interaction-starts 0
  set old-interaction-starts 0
  set interaction-ends 0
  set old-interaction-ends 0
  set active-interactions 0

  ;initial no. of infections
  set initial-infecteds 0
  set reinfectious 0

   ;environmental globals
  set externals  0
  set env0-color black
  set env1-color magenta
  set env2-color violet


 ;phase
  set phase-step 0
  set phase-time 0.00
  ifelse Phases = "Do Nothing"
  [ no-parameters ]
  [ ifelse Phases = "Limited Opening"
    [ limited-parameters ]
    [ ifelse Phases = "Phased Opening"
      [ set phase-time phased-parameters phase-step ]
      [ ifelse Phases = "Fully Open"
        [ fullyopen-parameters ]
        [ ifelse Phases = "Lockdown"
          [ lockdown-parameters ]
          [ interface-parameters ] ;"Custom" case is the default
        ]
      ]
    ]
  ]

  if printing? [ output-print (word "0::::Phase set to:" Phases) ]
  if verify? [ phase-summary ]

end

to-report seed-set [ my-seed seed-label ]

  ifelse randomize-seed?
  [
    set my-seed new-seed ;reset seed to random seed internally generated by Netlogo
    if printing? [ output-print (word "0::::Randomizing seed for " seed-label " to:" my-seed) ]
  ]
  [
    ;my-seed set on interface for this case
    if printing? [ output-print (word "0::::Manual seed for " seed-label " is:" my-seed) ]
  ]
  random-seed my-seed  ;this is what sets the seed for Netlogo whether manual or by Netlogo
  report my-seed       ;return the number my-seed for interface

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; RUNTIME
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go


  if (simlength > 0) [
    if ( ticks >= simlength ) ;or  ( count people with [ status = 3 ] = 0 )
    [
      if printing? [ print-summary ]
      stop
    ]
  ]

  ;
  if Phases = "Phased Opening"
  [
    if ticks > phase-time
    [
       set phase-time phased-parameters ( phase-step )
    ]
  ]

  ;Overview:
  ; 1. Check to see if person in a special environment that has its own rules. If person in an area that is designated,
  ;    they follow different set of rules.  Otherwise, they do the normal interaction in step 2.
  ;1. People who are not currently in an interaction will:
  ; (a) move a little
  ; (b) check to see if they are on an group setting patch, in which case rules change (TBD)
  ; (c) they check to see if someone is around to interact with based on social distancing
  ;2. If already interacting, they update their type.

  ;Note: In a group setting patch, person will partner with "self" - which ignores personal interactions.
  ;So there are different rules available in envioronmental area.

  ask people
  [
    if Environment? [ external-rules-of-engagement ]
    if in-external? = FALSE[ if Social-Interaction? [ interact-socially ] ]

    ;check health
    check-health    ;this controls what happens to an individual outside of interactions with other people

  ]

   if printing? [ if remainder ticks 100 = 0 [ print-summary ] ]

  ;plots are controlled by specific routines, not by update-plots primitive (which is run by tick now)
  ;histograms were initialized in setup but other plots and monitors do not need to be initialized
  update-plot-data
  update-histograms
  update-monitors

  ;clock update
  tick
  set time-units time-units + 1  ;keep track of time.  For now, just set to ticks but can alter at some point


end
@#$#@#$#@
GRAPHICS-WINDOW
664
10
1241
588
-1
-1
1.897
1
10
1
1
1
0
1
1
1
0
299
0
299
1
1
1
ticks
30.0

BUTTON
239
30
306
79
NIL
Setup
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
433
30
539
79
On/Off
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
480
80
658
113
total-population
total-population
0
10000
10000.0
1
1
people
HORIZONTAL

SLIDER
178
381
344
414
prob-interaction
prob-interaction
0
100
90.0
0.1
1
%
HORIZONTAL

SLIDER
181
413
344
446
avg-interaction
avg-interaction
0
100
20.0
1
1
ticks
HORIZONTAL

PLOT
1250
386
1880
792
Summary
Simulated Time
Number of People
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"healthy" 1.0 0 -13840069 true "" ""
"susceptible" 1.0 0 -10899396 true "" ""
"exposed" 1.0 0 -955883 true "" ""
"infectious" 1.0 0 -2674135 true "" ""
"hospitalized" 1.0 0 -11221820 true "" ""
"recovered" 1.0 0 -6459832 true "" ""
"deceased" 1.0 0 -14730904 true "" ""
"reinfected" 1.0 0 -5825686 true "" ""
"quarantined" 1.0 0 -7500403 true "" ""
"total" 1.0 0 -16777216 true "" ""

SLIDER
480
114
658
147
prob-asymptomatic
prob-asymptomatic
0
100
15.0
1
1
%
HORIZONTAL

SLIDER
169
118
318
151
setup-seed
setup-seed
-2147483648
2147483647
1.775093007E9
1
1
NIL
HORIZONTAL

SLIDER
256
81
466
114
movement
movement
0
10
1.0
1
1
patches per move
HORIZONTAL

SWITCH
346
317
495
350
Testing?
Testing?
0
1
-1000

TEXTBOX
421
557
519
576
Environment
16
15.0
0

SLIDER
4
602
185
635
Initial-Infection
Initial-Infection
0
100
15.0
1
1
%
HORIZONTAL

SLIDER
492
675
652
708
size-of-environment
size-of-environment
1
int ((max-pxcor + 1) / num-of-environments)
1.0
1
1
NIL
HORIZONTAL

SWITCH
418
582
653
615
Environment?
Environment?
1
1
-1000

SLIDER
418
764
653
797
time-in-environment
time-in-environment
0
simlength
0.0
1
1
time units
HORIZONTAL

PLOT
1247
12
1458
132
Initial Population
Asy  Mild   Med   Sers   Sev
Frequency
0.0
6.0
0.0
10.0
true
false
"" ""
PENS
"kind" 1.0 1 -13345367 true "" ""

SLIDER
480
147
658
180
prob-mild-symptoms
prob-mild-symptoms
0
100
34.0
1
1
%
HORIZONTAL

SLIDER
480
179
657
212
prob-medium-symptoms
prob-medium-symptoms
0
100
29.0
1
1
%
HORIZONTAL

SLIDER
479
212
657
245
prob-serious-symptoms
prob-serious-symptoms
0
100
16.0
1
1
%
HORIZONTAL

SLIDER
479
244
658
277
prob-severe-symptoms
prob-severe-symptoms
0
100
6.0
1
1
%
HORIZONTAL

SLIDER
418
614
655
647
smoothness
smoothness
0
50
0.0
1
1
repeitions
HORIZONTAL

SLIDER
197
631
391
664
mild-symptoms
mild-symptoms
0
100
99.0
1
1
%
HORIZONTAL

SLIDER
197
663
391
696
medium-symptoms
medium-symptoms
0
100
96.0
1
1
%
HORIZONTAL

SLIDER
197
696
390
729
serious-symptoms
serious-symptoms
0
100
95.0
1
1
%
HORIZONTAL

SLIDER
198
729
389
762
severe-symptoms
severe-symptoms
0
100
85.0
1
1
%
HORIZONTAL

SLIDER
16
81
253
114
simlength
simlength
1
8760
1000.0
1
1
NIL
HORIZONTAL

BUTTON
362
30
431
78
Step 10
go go go go go go go go go go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
307
31
362
79
Step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
1459
133
1673
253
Infectious
Asy  Mild   Med   Sers   Sev
#
0.0
6.0
0.0
10.0
true
false
"" ""
PENS
"kind" 1.0 1 -13345367 false "" ""

SLIDER
196
601
391
634
asymptomatic
asymptomatic
0
100
100.0
1
1
%
HORIZONTAL

MONITOR
543
34
659
79
Sum to 100%:
prob-asymptomatic + prob-mild-symptoms + prob-medium-symptoms + prob-serious-symptoms + prob-severe-symptoms
0
1
11

OUTPUT
667
600
1245
791
12

PLOT
1249
133
1458
253
Exposures
 # contacts
Frequency
0.0
50.0
0.0
20.0
true
false
"" ""
PENS
"kind" 1.0 1 -13345367 true "" ""

SWITCH
16
118
168
151
randomize-seed?
randomize-seed?
0
1
-1000

TEXTBOX
15
10
165
30
Runtime Parameters
16
15.0
1

MONITOR
1744
114
1814
159
Exp Mean
mean [length memory] of people
2
1
11

TEXTBOX
11
328
190
350
Susceptibility if Exposed
16
15.0
1

SLIDER
498
484
660
517
Percent-vaccinated
Percent-vaccinated
0
100 - Initial-Infection
50.0
1
1
%
HORIZONTAL

SWITCH
179
350
344
383
Social-interaction?
Social-interaction?
0
1
-1000

SLIDER
317
118
465
151
go-seed
go-seed
-2147483648
2147483648
1.06785567E9
1
1
NIL
HORIZONTAL

SLIDER
418
648
653
681
num-of-environments
num-of-environments
1
10
1.0
1
1
NIL
HORIZONTAL

MONITOR
418
683
491
728
Size <= 
int ((max-pxcor + 1) / num-of-environments)
0
1
11

SWITCH
418
728
653
761
never-leave?
never-leave?
1
1
-1000

SWITCH
181
446
344
479
social-distance?
social-distance?
0
1
-1000

SWITCH
15
154
122
187
printing?
printing?
0
1
-1000

SWITCH
124
154
237
187
verify?
verify?
1
1
-1000

TEXTBOX
201
328
351
348
Social Interaction
16
15.0
1

SLIDER
181
480
344
513
prob-distancing
prob-distancing
0
100
50.0
1
1
%
HORIZONTAL

BUTTON
238
155
349
188
Export Model
export-model
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
3
763
183
796
Contact Lists
check-memory
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
351
155
465
188
Write Report
write-custom-report
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
5
577
91
597
Exposure
16
15.0
1

TEXTBOX
198
579
348
599
Recovery/Reinfection
16
15.0
1

TEXTBOX
349
293
499
313
Prevention
16
15.0
1

PLOT
1460
12
1673
132
Susceptible
Asy  Mild   Med   Sers   Sev
Frequency
0.0
6.0
0.0
10.0
true
false
"" ""
PENS
"kind" 1.0 1 -13345367 true "" ""

PLOT
1457
255
1675
375
Recovered
Asy  Mild   Med   Sers   Sev
#
0.0
6.0
0.0
10.0
true
false
"" ""
PENS
"kind" 1.0 1 -13345367 true "" ""

SLIDER
198
763
390
796
reinfect-rate
reinfect-rate
0
100
50.0
1
1
%
HORIZONTAL

TEXTBOX
15
199
104
283
Population:\nAsymp (blue)\nMild (green)\nMedium (yellow)\nSerious (orange)\nSevere (red) 
11
0.0
1

MONITOR
1677
17
1878
62
Initial infectious
initial-infecteds
17
1
11

SLIDER
344
517
494
550
Mask-effectiveness
Mask-effectiveness
0
100
80.0
1
1
%
HORIZONTAL

SLIDER
3
633
184
666
Infection-Rate
Infection-Rate
0
100
80.0
1
1
%
HORIZONTAL

PLOT
1249
253
1460
373
Hospitalized
Asy  Mild   Med   Sers   Sev
#
0.0
6.0
0.0
10.0
true
false
"" ""
PENS
"kind" 1.0 1 -13345367 true "" ""

MONITOR
1814
114
1881
159
Infectious
count people with [ status = 3]
17
1
11

SLIDER
4
665
183
698
incubation-period
incubation-period
7
1000
180.0
1
1
ticks
HORIZONTAL

TEXTBOX
162
192
312
318
Status:\n  Person - healthy\n  Neutral - susceptible\n  Sad Face - exposed\n  Bug - infectious\n  Target - hospitalized\n  Happy Face - recovered\n  Star - possible reinfection\n  Flag - again infectious
11
0.0
1

TEXTBOX
16
290
198
318
Contacts: \nPink (New), Sky (Repeat)
11
0.0
1

SLIDER
5
350
181
383
susceptibility-asymptomatic
susceptibility-asymptomatic
0
100
20.0
1
1
%
HORIZONTAL

SLIDER
3
381
180
414
susceptibility-mild
susceptibility-mild
0
100
30.0
1
1
%
HORIZONTAL

SLIDER
4
413
180
446
susceptibility-medium
susceptibility-medium
0
100
50.0
1
1
%
HORIZONTAL

SLIDER
0
446
181
479
susceptibility-serious
susceptibility-serious
0
100
75.0
1
1
%
HORIZONTAL

SLIDER
0
479
181
512
susceptibility-severe
susceptibility-severe
0
100
90.0
1
1
%
HORIZONTAL

SLIDER
0
729
183
762
illness-factor
illness-factor
1
100
7.0
.5
1
ticks
HORIZONTAL

SLIDER
4
697
184
730
infectious-length
infectious-length
7
1000
360.0
1
1
ticks
HORIZONTAL

MONITOR
1813
161
1880
206
Deceased
count people with [ status = 6 ]
0
1
11

MONITOR
1677
208
1779
253
Reinfected
reinfectious
0
1
11

MONITOR
1745
161
1813
206
Recovered
count people with [status = 5]
0
1
11

BUTTON
145
30
238
78
Reset Plots
clear-all-plots\nclear-output
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
496
419
658
452
Vaccine?
Vaccine?
0
1
-1000

SLIDER
345
381
494
414
Test-effectiveness
Test-effectiveness
0
100
80.0
1
1
%
HORIZONTAL

SLIDER
494
384
657
417
Quarantine-length
Quarantine-length
7
28
14.0
1
1
ticks
HORIZONTAL

SLIDER
497
452
659
485
Vaccine-Effectiveness
Vaccine-Effectiveness
0
100
90.0
1
1
%
HORIZONTAL

MONITOR
1677
114
1744
159
Exposed
count people with [ status = 2]
17
1
11

MONITOR
1676
162
1745
207
Hospitalized
count people with [status = 4]
17
1
11

MONITOR
1776
209
1882
254
Quarantined
count people with [status = 8]
0
1
11

MONITOR
1775
65
1880
110
Susceptible
count people with [ status = 1]
0
1
11

MONITOR
1677
65
1773
110
Healthy
count people with [ status = 0]
0
1
11

SLIDER
495
350
657
383
Self-quarantined
Self-quarantined
0
100
80.0
1
1
%
HORIZONTAL

PLOT
1677
255
1883
375
Deceased
Asy  Mild   Med   Sers   Sev
#
0.0
6.0
0.0
10.0
true
false
"" ""
PENS
"kind" 1.0 1 -16777216 true "" ""

CHOOSER
15
34
142
79
Phases
Phases
"Custom" "Lockdown" "Limited Opening" "Phased Opening" "Fully Open" "Do Nothing"
0

SWITCH
493
318
658
351
Self-quarantine?
Self-quarantine?
0
1
-1000

SLIDER
346
482
494
515
Wear-Masks
Wear-Masks
0
100
50.0
1
1
%
HORIZONTAL

SWITCH
346
450
494
483
Masks?
Masks?
0
1
-1000

SLIDER
347
416
494
449
Test-quarantine
Test-quarantine
0
100
14.0
1
1
%
HORIZONTAL

SLIDER
347
350
494
383
Tested
Tested
0
100
75.0
1
1
%
HORIZONTAL

@#$#@#$#@
# WHAT IS IT? 
## Status

Have not yet implemented vaccines or masks.

This is a model of pandemics in a fixed population size (set by the modeler).

## SEIR Models of Pandemics

The model is similar in focus to the "SEIR/SEIRS" concept:

  (a) Susceptibility to getting infection if exposed
  (b) Exposure - exposed to infectious people
  (c) Infectious - infectious after incubation period
  (d) Recovery - includes hospitalization, recovery, death
  (e) Susceptibility to re-infection (i.e., limited immunity -> reinfection)
  
SEIR models generally use differential equations, so there are parameters
for the transition from each category to the next. For example, there is
a parameter for the rate at which susceptible people get exposed to 
infection.  Another parameter focuses on the rate at which exposed people 
become infectious themselves. Another parameter indicates the rate of 
recovery. Recovery is really recovery / mortality in these models. Some
models add limited immunity, so they can be susceptible again (SEIRS). A
good discussion of SEIR / SEIRS models is given at 
https://www.idmod.org/docs/hiv/model-seir.html.

## Agent-Based Modeling (ABM)

Agent-based models are a little different from SEIR differential equation
models. Individual agents are created and assigned to one of five
demographic groups:

  (a) asymptotic
  (b) mild
  (c) medium
  (d) serious
  (e) severe
  
These terms refer to what happens if the agent gets infected.  An 
asymptomatic person shows no outward signs of illness, whereas a severe
agent means they have a very low probability of survival. (Note that 80%
of people on ventilators die in non-COVID cases; it's closer to 88% with
COVID.)

The modeler sets the percentage of the population in each category and then
sets a number of parameters related to, but not using the same approach, as SEIR models. People
roam around the state space, potentially interacting with others who may be healthy, susceptible, 
exposed, infectious, recovered or reinfected.  Hospitalized people do not, by definition, roam around;
same for deceases(!)  When two people meet, there is a probability that they are suseceptible to 
their partner's health. If the partner is infectious, then a susceptible person has been exposed and,
depending on their demographic type.

The model has a social interaction component, as well as an environmental component that will be 
described below.  Histograms provide an overview of the initial population,
those that are susceptible in each demographic category.  Exposures are
also listed by demographic and keep a contact list for each individuals
for future modeling use.  Infections, hosptializations, recoveries, deaths
and re-infections are also tallied.

# MODEL OVERVIEW

The model is divided into 12 sections as seen on the interface tab.  Details
will be provided in the next section, but an overview is as follows:

## Interface - an overview provided here - see MODEL SETUP for details

### Runtime parameters

Simulation length, printing options, and random seeds are defined here.  This section also
includes the number of patches traversed in each clock tick ("move") and whether links
should be displayed.

### Demographic parameters

The total number of people in the model is set here, and the population is divided into
five "kinds" of people representing different susceptibilities to infection.  

### Susceptibility if Exposed

The actual susceptibility of each "kind" of person to infection is set here

### Social Interactions

A switch turns on the social interaction part of the model.  People move about the state space
and may interact with someone on the same patch.  There is a probability of such an interaction
occurring, as well as an average number of time units for each interaction.  Without the switch
being on, people may still be on the same patch but will not actually interact with anyone. This
is not the same as social distancing - it just turns off the interaction part of the code.

### Prevention

This part of the model focuses on actions taken to lower infection rates.  If social distancing is turned on,
the model checks to see if there is an empty patch in the 8 patches surrounding the current location. If
not, the user does not move.  There is a probability of following this rule - those that do not just
move around as if there is no social distaincing.

The other three options here have not yet been implemented:

	(a) Testing
	(b) Quarantining
	(c) Vaccination

### Exposure

This section sets up several parameters regarding infection rates once exposed:

	(a) initial-infection rate - model needs to have some infectious people at beginning
	(b) infection-rate - what's the rate of getting infected during an interaction with an      
	    infectious person
	(c) incubation period - how long before an exposed person who has become infected shows   
	    symptoms and becomes infectious themselves
	(d) infectious-length - how long the person is infectious before changing status to hospitalized,
	    quarantined, etc.  This has not been fully implemented in the current model (since quarantined
		not yet simulated)
	(e) illness factor - general factor multiplied by the "kind" of person to determine how serious
	    the illness is for that agent.

### Recovery

Each "kind" of person has a probability of full recovery.

### Reinfection

There is a possible reinfection-rate - where a recovered person can lose their immunity.

### Environment

This section has not been fully implemented.  The user can set up one or more environments and "smooth" out the
characteristics of that environment so there are no sudden jumps in environmental conditions from one
patch to another.  There are parameters for movement and length of time spent in the environment.  There is also 
a rate of infection in these environments that is dependent on the smoothness result and a general parameter.
The intent is that the environment would represent interactions with the environment instead of person-to-person
contact.  If social interaction is turned on, it does not apply within an environment.

### Visualization

The model is displayed during runtime in the black square in the middle of the interface.  Each "kind" of
person is represented in a different color, from blue for asymptomatic people to red for people who face 
severe consequences if infected.

The status of the person's health is shown by the shape of the icon for each person - a "person" if
healthy, a bug if infectious, etc.

When two people interact, the patch is colored - "sky" if these people have interacted before and "pink" if
a new interaction is occurring.  If so, they are added to a contact list for each individual.

### Output

All print and verification output goes into a small output display below the black square.  This information
can be exported via the "Export Model" button in the Runtime Parameters area of the interace.  This button
also exports standard reports from the Netlogo application.

Another button in the "Runtime Parameters" section, "Write Report," is only partially implemented.  This
will be a more "formal" report of the output when completed.

### Results

This section contains several graphs showing key results from the model.  Hisograms are used to show how
many of each "kind" are in the initial population, are susceptible, exposed, infectiouis, hospitalized and recovered.

Several monitors displays results as well, and a temporal plot shows the number of agents in each "status"
category over the life of the model.

# MODEL SETUP

## Code Tab

This is the .nlogo file that is used to open and execute the model.  Its components are listed below:

### Include Files

To maintain the model, several "include" files (extension .nls) are used to organize the code.

#### people.nls

Sets up the initial population and assigns default characteristics for each kind of person
in the model. Modules within this file also check variables during the execution of the model that pertain
to each agent in the model, such as "check-health."

#### interact.nls

This file focuses on the rules for interacting with other agents, such as deciding whether an interaction
will occur and what happens during an interaction.  It is here where an agent's status can change based
on the interaction.


#### environment.nls

This file sets up one or more non-overlapping environments in which the rules may differ from regions outside\
the environment.  No social interactions occur here, so this could be an alternative to the social 
distancing parameter used in the interactive portion of the model.  

At this point, the environments are set up and people can move around inside the environment for a
designated period of time. However, the rules have not yet been established for what impacts agents.  
Only the movement of people has been simulated.  See "external-rules-of-engagement" for the current
level of detail.

Patch intensity is used to colorize the environment.  Then a smoothly function is set to remove abrupt
transitions between patches.  The patch intensity factors are rescaled (see "fitness" model in
the Netlogo library) and recolored according to the intensity attribute.

#### graphics.nls

The graphics.nls file sets up and maintains all graphics used in the Results section of the interface.

#### report.nls

This file is used to print summary stats, export model components and create a custom report.  The custom
report is still being developed.

### Extensions

Extensions expand the capabilities of Netlogo code.  The movie extension is included here, though it
is old code and needs to be updated to work with the latest version of Netlogo.

###Breeds

All agents in Netlogo are considered "turtles" unless specific breeds are defined.  People constitute the
only agents in this model

### Globals

Globals are defined here or on the interface itself.  Monitors and counters are included here.

### Patches-own

Each patch has built-in attributes (e.g., [x][y] coordinates), as well as custom attributes set here, like 
intensity (to exhibit a color representing degree of some attribute) and original-color, to revert to 
the initial color of that patch.

### People-own

Attributes for each user, such as type of user ("kind"), health "status", and various flags and time
recorders are included here.

The most interesting attribute is "memory," a contact list of who you have interacted with over time.

###  Setup

This set of modules set up the plot - globals are initialized, the environment is established and
people are created.  Monitors and graphs are initialized, and random number seeds are set up.


### Go

This is the runtime portion of the model.  A loop goes through all the people in the model.  If the 
environment is used, those rules of engagement are executed.  Otherwise, it checks to see if social
interactions are in effect.  If Yes, the person interacts with others and then moves to another space. 
In either case, the individual's health is checked.

Currently, the model is either external or internal, not both.

## Interface Tab

# HOW IT WORKS 


# HOW TO USE IT


# THINGS TO TRY


# EXTENDING THE MODEL 

## Testing

## Quarantine

## Vaccination

## Herd immunity

## Movie

## Environmental Rules

## Environment + Social Interaction

# NETLOGO FEATURES 

## Includes

## Extensions

## Breeds

To determine the rest of the population, an array is set up in the initialization part of the model: 

    ;The first entry is the category type; the second is a probability. 
    set kind-structure [ [ 2 12 ] [ 3 47 ] [ 4 81 ] [ 5 100 ] ]  

This is used in the following reporter routine:   

    to-report determine-kind [ probability-index ]  
      let this_kind first ( first ( filter [ last ? >= probability-index ] 
            kind-structure ) )
      print this_kind+":"+probability-index+":"+filter 
            [ last ? >= probability-index ] kind-structure  
      report (this_kind)  
    end  

The "let" statement was graciously explained to me through the community web pages. This routine is called during setup in this model to determine the kind of person.


# CREDITS AND REFERENCES 

## Other Models 

### Sample Models

The framework for this model is based on two great models on the Netlogo web site: 

  (a) AIDS - Copyright 1997 Uri Wilensky. All rights reserved. This provided the basic idea of pairing individuals on the same patch. 

  (b) Fitness Landscape - Copyright 2006 David McAvity. This model, from the Community Models section of the Netlogo web site, was created at the Evergeen State College, in Olympia Washington as part of a series of applets to illustrate principles in physics and biology. 

  (c) Virus

### Community Models
  
#### Diffusion of Innovations
  
  
#### COVID-19 models
  
## References 


# COPYRIGHT INFORMATION

Copyright 2020 Michael Samuels

   
========================  
Last updated: 06/08/2020 
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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 109 6 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Circle -1184463 true false 126 33 14
Circle -1184463 true false 156 34 13
Line -1184463 false 158 70 167 62
Polygon -1184463 true false 141 63 148 40 154 63
Rectangle -1184463 true false 135 70 160 75
Line -1184463 false 134 70 126 61
Polygon -1184463 true false 58 162 34 196 37 190
Rectangle -16777216 true false 30 180 45 195
Rectangle -16777216 true false 45 180 60 165
Rectangle -16777216 true false 60 180 45 165
Rectangle -16777216 true false 45 165 60 180

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Self-quarantine" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ status = 1]</metric>
    <metric>count turtles with [ status = 2]</metric>
    <metric>count turtles with [ status = 3]</metric>
    <metric>count turtles with [ status = 4]</metric>
    <metric>count turtles with [ status = 5]</metric>
    <metric>count turtles with [ status = 6]</metric>
    <metric>count turtles with [ status = 7]</metric>
    <metric>count turtles with [ status = 8]</metric>
    <enumeratedValueSet variable="Social-interaction?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="medium-symptoms">
      <value value="98"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-environments">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="susceptibility-severe">
      <value value="86"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-interaction">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-distancing">
      <value value="95"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Self-quarantined" first="25" step="25" last="100"/>
    <enumeratedValueSet variable="incubation-period">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simlength">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="susceptibility-asymptomatic">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoothness">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Phases">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="susceptibility-medium">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movement">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-severe-symptoms">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Infection">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Quarantine-length">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="illness-factor">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-mild-symptoms">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Quarantined">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infectious-length">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reinfect-rate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="severe-symptoms">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Self-quarantine?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Testing?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-population">
      <value value="252"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="size-of-environment">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-distance?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine-Effectiveness">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setup-seed">
      <value value="1775093007"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="printing?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="susceptibility-serious">
      <value value="74"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-effectiveness">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="never-leave?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mild-symptoms">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomize-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="susceptibility-mild">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-medium-symptoms">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Environment?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serious-symptoms">
      <value value="97"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verify?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-serious-symptoms">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-in-environment">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-frames">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Infection-Rate">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymptomatic">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="go-seed">
      <value value="1067855670"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Quarantine?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percent-vaccinated">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-asymptomatic">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avg-interaction">
      <value value="10"/>
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
