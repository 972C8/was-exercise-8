// sensing agent


/* Initial beliefs and rules */

// Task 2.1.2
// Using lecture slides and https://github.com/andreiciortea/was-lecture8-moise/blob/main/src/agt/simple_agent.asl
role_goal(R, G) :-
   role_mission(R, _, M) & mission_goal(M, G).

can_achieve(G) :-
   .relevant_plans({+!G[scheme(_)]}, LP) & LP \== [].

i_have_plan_for_role(R) :-
   not (role_goal(R, G) & not can_achieve(G)).


/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : true <-
	.print("Hello world").

/*
 * Task 2.1.1: Joining the organization workspace
 * Plan for reacting to the creation of new organization workspaces
 * Triggering event: creation of a new organization workspace
 * Context: the agent believes that an organization workspace is created
 * Body: joins workspace, looks up artifacts and focuses
*/
@org_created_plan
+org_created(OrgName) : true <-
	joinWorkspace(OrgName);
	lookupArtifact(OrgName, OrgArtId);
	focus(OrgArtId).

/*
 * Task 2.1.1: Observing properties and events that relate to the organization.
 * Plan for reacting to the creation of new group
 * Triggering event: creation of a new group
 * Context: the agent believes that a group is created
 * Body: looks up group, focuses on it and scans the group specification
*/
@group_plan
+group(GroupId, GroupType, GroupArtId) : true <-
	focus(GroupArtId);
	!observe_specifications_of_group(GroupArtId).

/*
 * Task 2.1.1: Observing properties and events that relate to the organization.
 * Plan for reacting to the creation of new scheme
 * Triggering event: creation of a new scheme
 * Context: the agent believes that a scheme is created
 * Body: focuses on the scheme
*/
@scheme_plan
+scheme(SchemeId, SchemeType, SchemeArtId) : true <-
	focus(SchemeArtId).

/*
 * Task 2.1.2: Reasons on the organization and adopts all its relevant roles
 * Plan for scanning the group specification
 * Triggering event: creation of a new group
 * Context: the agent believes that a group is created
 * Body: scans the group specification and reasons on the organization and adoption of relevant roles
*/
@observe_specifications_of_group_plan
+!observe_specifications_of_group(GroupArtId) : specification(group_specification(GroupName,RolesList,_,_)) <-
	for ( .member(Role,RolesList) ) {
    !reason_role_adoption(Role);
	}.

/*
 * Task 2.1.2: Plan for reasoning on the role adoption
 * Triggering event: reasoning for role adoption
 * Context: the agent believes that it has a plan for the role
 * Body: prints the role and adopts it
*/
@reason_role_adoption_plan
+!reason_role_adoption(role(Role,_,_,MinCard,MaxCard,_,_)) : i_have_plan_for_role(Role) <-
	.print("I have a plan for the role: ", Role);
	adoptRole(Role).

/*
 * Task 2.1.2: Plan for failure of reasoning on the role adoption
 * Triggering event: reasoning for role adoption
 * Context: the agent believes that it does not have a plan for the role
*/
@reason_role_adoption_plan_fail
+!reason_role_adoption(role(Role,_,_,MinCard,MaxCard,_,_)) : true <-
	true.

/* 
 * Plan for reacting to the addition of the goal !read_temperature
 * Triggering event: addition of goal !read_temperature
 * Context: true (the plan is always applicable)
 * Body: reads the temperature using a weather station artifact and broadcasts the reading
*/
@read_temperature_plan
+!read_temperature : true <-
	.print("I will read the temperature");
	makeArtifact("weatherStation", "tools.WeatherStation", [], WeatherStationId); // creates a weather station artifact
	focus(WeatherStationId); // focuses on the weather station artifact
	readCurrentTemperature(47.42, 9.37, Celsius); // reads the current temperature using the artifact
	.print("Temperature Reading (Celsius): ", Celsius);
	.broadcast(tell, temperature(Celsius)). // broadcasts the temperature reading

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }