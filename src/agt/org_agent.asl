// organization agent

/* Initial beliefs and rules */
org_name("lab_monitoring_org"). // the agent beliefs that it can manage organizations with the id "lab_monitoting_org"
group_name("monitoring_team"). // the agent beliefs that it can manage groups with the id "monitoring_team"
sch_name("monitoring_scheme"). // the agent beliefs that it can manage schemes with the id "monitoring_scheme"

// Task 2.2.1: Infer if there are enough players for a role
enough_players(R) :-
  role_cardinality(R,Min,Max) &
  .count(play(_,R,_),NP) &
  NP >= Min.

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : org_name(OrgName) & group_name(GroupName) & sch_name(SchemeName) <-
  .print("Hello world");

  // Task 1.1: The agent creates and joins an organization workspace
  createWorkspace(OrgName);
  joinWorkspace(OrgName, WorkspaceId);

  // Task 1.2: The agent creates and focuses on an Organization Board artifact
  makeArtifact(OrgName, "ora4mas.nopl.OrgBoard", ["src/org/org-spec.xml"], OrgBoardArtId)[wid(WorkspaceId)];
  focus(OrgBoardArtId)[wid(WorkspaceId)];

  // Task 1.3: The agent uses the Organization Board artifact to create and focus on organizational artifacts
  createGroup(GroupName, GroupName, GroupArtId)[artifact_id(OrgBoardArtId)];
  focus(GroupArtId)[wid(WorkspaceId)];

  createScheme(SchemeName, SchemeName, SchemeArtId)[artifact_id(OrgBoardArtId)];
  focus(SchemeArtId)[wid(WorkspaceId)];

  // Task 1.4: The agent broadcasts that a new organization workspace is available
  .broadcast(tell, org_created(OrgName));
  
  !inspect(GroupArtId)[wid(WorkspaceId)];
  !inspect(SchemeArtId)[wid(WorkspaceId)];

  // Task 1.5: Add test goal for the formation status of the group, and wait for the group to become well-formed
  ?formationStatus(ok)[artifact_id(GroupArtId)].

/* 
 * Plan for reacting to the addition of the test-goal ?formationStatus(ok)
 * Triggering event: addition of goal ?formationStatus(ok)
 * Context: the agent beliefs that there exists a group G whose formation status is being tested
 * Body: if the belief formationStatus(ok)[artifact_id(G)] is not already in the agents belief base
 * the agent waits until the belief is added in the belief base
*/
@test_formation_status_is_ok_plan
+?formationStatus(ok)[artifact_id(GroupArtId)] : group(GroupName,_,GroupArtId)[artifact_id(OrgName)] <-
  .print("Waiting for group ", GroupName," to become well-formed");
  // Task 2.2.1: Every 15 seconds the agent infers whether there exist any roles for which the team does not have enough players.
  .wait(15000);
  !fill_group_with_players(GroupName);
  .wait({+formationStatus(ok)[artifact_id(GroupArtId)]}). // waits until the belief is added in the belief base

/*
 * Task 1.5: Reacting to the addition of the belief formationStatus(ok)
 * Triggering event: addition of belief formationStatus(ok)[artifact_id(G)]
 * Context: the agent beliefs that there exists a group G whose formation status is ok
 * Body: the agent announces that the group is well-formed and can work on the scheme
*/
@formation_status_is_ok_plan
+formationStatus(ok)[artifact_id(GroupArtId)] : group(GroupName,_,GroupArtId)[artifact_id(OrgName)] & scheme(SchemeName,SchemeType,SchemeArtId) <-
  .print("Group ", GroupName, " is well-formed.");
  addScheme(SchemeName)[artifact_id(GroupArtId)];
  focus(SchemeArtId).

/*
  * Task 2.2.1: Every 15 seconds the agent strives to create a well-formed group.
  * Plan for reacting to the addition of the goal !fill_group_with_players(GroupName)
  * Triggering event: addition of goal !fill_group_with_players(GroupName)
  * Context: the agent beliefs that there exists a group G whose formation status is being tested
  * Body: the agent checks if there are enough players for each role in the group G and tries to complete the group formation
*/
@fill_group_with_players_plan
+!fill_group_with_players(GroupName) : formationStatus(nok) & group(GroupName,GroupType,GroupArtId) & org_name(OrgName) & specification(group_specification(GroupName,RolesList,_,_)) <-
  for ( .member(Role,RolesList) ) {
    !check_enough_players(Role);
  }
  .wait(15000);
  !fill_group_with_players(GroupArtId).

/*
  * Task 2.2.1: Default plan for reacting to the addition of the goal !fill_group_with_players(GroupName)
  * Triggering event: addition of goal !fill_group_with_players(GroupName)
  * Context: true (the plan is always applicable)
  * Body: the agent does nothing
*/
@fill_group_with_players_plan_fail
+!fill_group_with_players(GroupName) : true <-
  true.

/*
  * Task 2.2.1: If there are not enough players for a role, broadcast to ask for fulfilling the role
  * Plan for reacting to the addition of the goal to check if there are enough players for a role
  * Triggering event: addition of goal !check_enough_players(role(Role,_,_,MinCard,MaxCard,_,_))
  * Context: the agent beliefs that there exists a group G whose formation status is being tested
  * Body: the agent broadcasts to ask for fullfilling the role
*/
@check_enough_players_plan
+!check_enough_players(role(Role,_,_,MinCard,MaxCard,_,_)) : not enough_players(Role) & org_name(OrgName) & group_name(GroupName) <-
  .print("Not enough players for role: ", Role);
  .broadcast(tell, adopt_role(Role, GroupName, OrgName)).
/*
  * Task 2.2.1: Default plan to check if there are enough players for a role
  * Triggering event: addition of goal !check_enough_players(role(Role,_,_,MinCard,MaxCard,_,_))
  * Context: true (the plan is always applicable)
  * Body: the agent does nothing
*/
@check_enough_players_plan_fail
+!check_enough_players(role(Role,_,_,MinCard,MaxCard,_,_)) : true <-
  true.

/* 
 * Plan for reacting to the addition of the goal !inspect(OrganizationalArtifactId)
 * Triggering event: addition of goal !inspect(OrganizationalArtifactId)
 * Context: true (the plan is always applicable)
 * Body: performs an action that launches a console for observing the organizational artifact 
 * identified by OrganizationalArtifactId
*/
@inspect_org_artifacts_plan
+!inspect(OrganizationalArtifactId) : true <-
  // performs an action that launches a console for observing the organizational artifact
  // the action is offered as an operation by the superclass OrgArt (https://moise.sourceforge.net/doc/api/ora4mas/nopl/OrgArt.html)
  debug(inspector_gui(on))[artifact_id(OrganizationalArtifactId)]. 

/* 
 * Plan for reacting to the addition of the belief play(Ag, Role, GroupId)
 * Triggering event: addition of belief play(Ag, Role, GroupId)
 * Context: true (the plan is always applicable)
 * Body: the agent announces that it observed that agent Ag adopted role Role in the group GroupId.
 * The belief is added when a Group Board artifact (https://moise.sourceforge.net/doc/api/ora4mas/nopl/GroupBoard.html)
 * emmits an observable event play(Ag, Role, GroupId)
*/
@play_plan
+play(Ag, Role, GroupId) : true <-
  .print("Agent ", Ag, " adopted the role ", Role, " in group ", GroupId).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }