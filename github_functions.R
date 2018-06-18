library(magrittr)
library(purrr)
library(gh)

make_student_repo <- function(orgName, repoName, auth, private = T, auto_init = T){
  
  repo_names <- gh("GET /orgs/:org/repos",
     org = orgName, 
     .token = auth) %>% 
    map_chr(., "name")
  
  ifelse(repoName %in% repo_names, 
         warning(glue::glue("{repoName} already exists in {orgName}. Skipping creation.")),
         gh("POST /orgs/:org/repos", 
                      org = orgName, 
                      name = repoName,
                      private = private,
                      has_issues = T,
                      has_projects = F,
                      has_wiki = F,
                      auto_init = auto_init,
                      .token = auth))
}

get_team_id <- function(orgName, teamName, auth){
  teams <- gh("GET /orgs/:org/teams", 
              org = orgName, 
              .token = auth) %>% 
    lapply(., data.frame) %>% 
    dplyr::bind_rows(.)
  
  if (!(teamName %in% teams$name)){
    stop(glue::glue("Error: {teamName} is not a team of {orgName}"))
  }
  teams %>% 
    dplyr::filter(name == teamName) %>% 
    .$id
}

assign_team_to_repo <- function(orgName, repoName, teamId, permission = "pull", auth){
  # from: https://stackoverflow.com/questions/43498035/add-github-team-in-org-to-a-repo
  # teamId is from `get_team_id`
  gh("PUT /teams/:id/repos/:org/:repo", 
    repo = repoName, 
    org = orgName,
    id = teamId,
    permission = permission,
    .token = auth)
}

add_student_to_repo <- function(orgName, repoName, userName, auth){
  gh("PUT /repos/:owner/:repo/collaborators/:username",
     owner = orgName,
     repo = repoName,
     username = userName,
     .token = auth)
}

add_student_to_team <- function(orgName, teamId, userName, auth){
  #gh("PUT /teams/:id/:org/memberships/:username",
  gh("PUT /teams/:id/memberships/:username",
     id = teamId,
     org = orgName,
     username = userName,
     .token = auth)
}

unwatch_repo <- function(orgName, repoName, auth){
  gh("DELETE /repos/:owner/:repo/subscription", 
     owner = orgName, 
     repo = repoName,
     .token = auth)
}

delete_student_repo <- function(orgName, repoName, auth){
  gh("DELETE /repos/:owner/:repo",
     owner = orgName,
     repo = repoName,
     .token = auth)
}



# setup:
# make students team on github
# get usernames and student names

# steps:
# 1. create repos for each student
#     - auto-initialize w/ README.md by default
# 2. add students to student team
# 2. give student team read access to other student repos
#     -instructors should have push access by default
# 3. add student as collaborator with push access to their own repo
# 4. unwatch student repos.

setup_course_repos <- function(repoNames, userNames, orgName, 
                               studentTeamName, 
                               instructorTeamName, 
                               auth, private = T, auto_init = T, student_team_repo_permission = "pull"){
  # where:
  # repoNames is a list of repository names
  # userNames is a list of usernames parallel to the repository name they will be assigned to
  
  if (length(repoNames) != length(userNames)){
    stop("ERROR: repoNames and userNames must be equal width")
  } 
  
  studentTeamId <- get_team_id(orgName, studentTeamName, auth)
  instructorTeamId <- get_team_id(orgName, instructorTeamName, auth)
  
  map2(repoNames, userNames, ~{
    repo <- .x
    user <- .y
    
    add_student_to_team(orgName, studentTeamId, userName = user, auth)
    make_student_repo(orgName, repoName = repo, auth, private = private, auto_init = auto_init)
    assign_team_to_repo(orgName, repoName = repo, studentTeamId, studentTeam_repo_permission, auth)
    assign_team_to_repo(orgName, repoName = repo, instructorTeamId, "push", auth)
    add_student_to_repo(orgName, repoName = repo, userName = user, auth)
    unwatch_repo(orgName, repoName = repo, auth)
    })
}
