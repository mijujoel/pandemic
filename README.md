# pandemic

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
