# Github R Course Administration Utilities
## Spencer Nystrom

[R Github Course](http://happygitwithr.com/)


# Prerequisites to using these tools

You will need to manually create a github organization and a team for students.
At a minimum, you will also need a list of your students github usernames.

A good template to follow can be found [here](http://happygitwithr.com/classroom-overview.html).

You'll also want to create a github token with admin access to your org. 

# Setting up your course with these scripts

## Requirements:
```{r}
pkgs <- c("magrittr", "purrr", "gh", "dplyr")
install.packages(pkgs)
```

## Quickstart:
These scripts will:
1. create repos for each student
1. add students to student team
1. give student team read access to other student repos
	- instructors should have push access by default if you set up the instructor team correctly
1. add student as collaborator to org with push access to their own repo
1. unwatch student repos.

- The following examples assume you've saved your github token in a plaintext file called 'auth.txt'

### Configure your working environment:
```{r}
source("github_functions")

orgName <- "organization_name"
teamName <- "students_team_name"
auth <- readr::read_file("auth.txt") %>%
	gsub("\n", "", .)

userNames <- c("testuser1", "testuser2")
```

### Setup (Quick)
This wil  create a repository named after each students' username. `repoNames` below can be any list that is parallel to `userNames`.
```{r}
setup_course_repos(repoNames = userNames, userNames = userNames, orgName, teamName, auth)
```

# Troubleshooting
## Delete repos if there are issues
```{r}
purrr::map(userNames, ~{delete_student_repo(orgName, ., auth)})
```