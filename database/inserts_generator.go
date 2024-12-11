package main

import (
	"bufio"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"strings"
)

func main() {
	// Setting up env...
	reader := bufio.NewReader(os.Stdin)
	seedText, err := reader.ReadString('\n')
	var seed int64
	if err != nil {
		fmt.Fprintf(os.Stderr, "Can't read seed from stdin! Generating new one...\n")
		fmt.Fprintln(os.Stderr, err)
		seed = rand.Int63()
	} else {
		seed, err = strconv.ParseInt(strings.TrimSpace(seedText), 10, 64)

		if err != nil {
			fmt.Fprintf(os.Stderr, "Can't parse seed from stdin! Generating new one...\n")
			fmt.Fprintln(os.Stderr, err)
			seed = rand.Int63()
		}
	}

	source := rand.NewSource(seed)
	random := rand.New(source)

	err = os.WriteFile(fmt.Sprintf("%d.seed", seed), []byte(fmt.Sprintf("%d\n", seed)), 0644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Can't write the file saving the last seed!\n")
		panic(err)
	}

	fmt.Fprintf(os.Stderr, "Creating with seed: %d\n", seed)

	// booleans := []string{"true", "false"}
	profilePictures := []string{
		"https://i.pinimg.com/474x/ce/01/a8/ce01a81ede670b25c1fe42ab53372be9.jpg",
		"https://pbs.twimg.com/profile_images/701573331661799424/Nz7S_Oie_400x400.png",
		"https://i.pinimg.com/474x/06/b6/d8/06b6d809fe220068117a61eea418c6c2.jpg",
		"https://windybot.com/thumb/0VdsmdWEquyKfjKEBH78.jpg",
		"https://i.pinimg.com/550x/ce/7f/68/ce7f6822998fc0a56c23c1c7a13c6483.jpg",
		"https://animegenius-global.live3d.io/vtuber/ai_product/anime_genius/static/imgs/chubby_e1bb9937fd9e35b1574a3e319de9f0ee.webp",
	}

	names := []string{
		"Naruto Uzumaki",
		"Goku",
		"Luffy",
		"Ichigo Kurosaki",
		"Mikasa Ackerman",
		"Natsu Dragneel",
		"Sakura Haruno",
		"Levi Ackerman",
		"Eren Yeager",
		"Light Yagami",
		"Kirito",
		"Hinata Hyuga",
		"Rem",
		"Saber",
		"Edward Elric",
		"Kenshin Himura",
		"Rin Tohsaka",
		"Asta",
		"Jotaro Kujo",
		"Yugi Muto",
		"Bulma",
		"Kaguya Shinomiya",
		"Tanjiro Kamado",
		"Homura Akemi",
		"Shoto Todoroki",
	}

	taskTypes := []string{"EPIC", "TASK", "SUBTASK"}
	taskNames := []string{
		"Programar endpoints del backend",
		"Programar a tu mami",
		"Ganar en TheFinals",
		"Terminar migración de JIRA a JUWURA",
		"Terminar de reescribir el universo en Rust",
		"Terminar script de migración",
		"POC: ¿Qué audífonos gamer comprar?",
		"POC: ¿Cogerse un trapito es gay?",
	}
	taskStatuses := []string{
		"TODO",
		"DOING",
		"DONE",
	}
	taskPriorities := []string{
		"HIGH",
		"MEDIUM",
		"LOW",
	}
	taskFieldTypes := []string{"TEXT", "DATE", "SELECT", "NUMBER"}

	// Changing to DB...
	fmt.Println("\\c juwura")

	// Generate app users...
	userCount := 8
	generatedEmails := make([]string, userCount)
	fmt.Println("INSERT INTO app_user (email, name, photo_url) VALUES")
	for i := range userCount {
		email := fmt.Sprintf("correo%d@gmail.com", i+1)
		name := from(random, names)
		photo := nullEveryPercent(random, 0.5, from(random, profilePictures))
		fmt.Printf("('%s', '%s', %s)", email, name, photo)

		generatedEmails[i] = email
		endInserts(i, userCount)
	}
	// fmt.Fprintln(os.Stderr, generatedEmails)
	fmt.Println()

	// Generate projects...
	projectCount := 5
	fmt.Println("INSERT INTO project (name, photo_url) VALUES")
	for i := range projectCount {
		name := fmt.Sprintf("Proyecto %s", from(random, names))
		photo := nullEveryPercent(random, 0.5, from(random, profilePictures))
		fmt.Printf("('%s', %s)", name, photo)

		endInserts(i, projectCount)
	}
	fmt.Println()

	// Generate project members...
	projectMembers := 3
	membersByProject := make([][]string, projectCount)
	fmt.Println("INSERT INTO project_member (project_id, user_id, is_pinned, last_visited) VALUES")
	for pIdx := range projectCount {
		userIdxs := random.Perm(userCount)
		for i := range projectMembers {
			projectId := pIdx + 1
			userId := generatedEmails[userIdxs[i%len(userIdxs)]]
			isPinned := defaultEveryPercent(random, 0.5, "true")
			fmt.Printf("(%d, '%s', %s, NOW())", projectId, userId, isPinned)

			membersByProject[pIdx] = append(membersByProject[pIdx], generatedEmails[userIdxs[i]])

			endInserts((pIdx+1)*(i+1)-1, projectCount*projectMembers)
		}
	}
	fmt.Println()

	// Generate task_types...
	// taskTypesCount := 3
	fmt.Println("INSERT INTO task_type VALUES ('EPIC'), ('TASK'), ('SUBTASK');")
	fmt.Println()

	// Generate tasks...
	taskCount := 10
	fmt.Println("INSERT INTO task (project_id, type, name, due_date, status, sprint, priority) VALUES")
	for projectIdx := range projectCount {
		for i := range taskCount {
			tType := from(random, taskTypes)
			name := nullEveryPercent(random, 0.3, from(random, taskNames))
			dueDate := nullEveryPercent(random, 0.5, "NOW()")
			status := nullEveryPercent(random, 0.5, from(random, taskStatuses))
			sprint := nullEveryPercent(random, 0.5, fmt.Sprintf("%d", random.Intn(10)))
			priority := nullEveryPercent(random, 0.8, from(random, taskPriorities))
			fmt.Printf("(%d, '%s', %s, %s, %s, %s, %s)", projectIdx+1, tType, name, dueDate, status, sprint, priority)

			endInserts((projectIdx+1)*(i+1)-1, projectCount*taskCount)
		}
	}
	fmt.Println()

	// Generate tasks unblocks...
	fmt.Println("INSERT INTO task_unblock (target_task, unblocked_task) VALUES")
	relationCount := 5
	for projectIdx := range projectCount {
		// Each project has #`taskCount` tasks,
		// so we need to delta de IDs to match up to tasks on the same project.
		delta := projectIdx * taskCount
		for relIdx := range relationCount {
			blockingTask := random.Intn(taskCount) + 1 + delta
			unblockedTask := random.Intn(taskCount) + 1 + delta
			fmt.Printf("(%d, %d)", blockingTask, unblockedTask)

			endInserts((projectIdx+1)*(relIdx+1)-1, projectCount*relationCount)
		}
	}
	fmt.Println()

	// Generate task assignees...
	fmt.Println("INSERT INTO task_assignee (task_id, user_id) VALUES")
	assigneeCount := taskCount * 3 / 2
	for projectIdx, members := range membersByProject {
		tasksIdxs := random.Perm(taskCount)
		membersIdxs := random.Perm(len(members))

		for assIdx := range assigneeCount {
			userId := members[membersIdxs[assIdx%len(membersIdxs)]]
			taskId := tasksIdxs[assIdx%len(tasksIdxs)] + 1 + projectIdx*taskCount

			fmt.Printf("(%d, '%s')", taskId, userId)

			endInserts((projectIdx+1)*(assIdx+1)-1, assigneeCount*len(membersByProject))
		}
	}
	fmt.Println()

	// Generate task field types...
	fmt.Println("INSERT INTO task_field_type (name, project_id) VALUES")
	for projecIdx := range projectCount {
		projectId := projecIdx + 1

		for idx, name := range taskFieldTypes {
			fmt.Printf("('%s', %d)", name, projectId)

			endInserts((idx+1)*(projecIdx+1)-1, projectCount*len(taskFieldTypes))
		}
	}

	// TODO: Generate custom fields for some projects...
}

func endInserts(i int, count int) {
	if i+1 == count {
		fmt.Print(";")
	} else {
		fmt.Print(",")
	}

	fmt.Println()
}

func nullEveryPercent(r *rand.Rand, percent float32, okValue string) string {
	okMapped := fmt.Sprintf("'%s'", okValue)
	return everyPercent(r, percent, "NULL", okMapped)
}

func defaultEveryPercent(r *rand.Rand, percent float32, okValue string) string {
	okMapped := fmt.Sprintf("'%s'", okValue)
	return everyPercent(r, percent, "default", okMapped)
}

func everyPercent[T any](r *rand.Rand, percent float32, okValue T, elseValue T) T {
	needle := r.Float32()
	if needle < percent {
		return okValue
	} else {
		return elseValue
	}
}

func from[T any](r *rand.Rand, slice []T) T {
	index := r.Intn(len(slice))
	v := slice[index]

	return v
}
