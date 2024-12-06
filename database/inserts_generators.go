package main

import (
	"bufio"
	"fmt"
	"math/rand"
	"os"
	"strconv"
)

func main() {
	// Setting up env...
	reader := bufio.NewReader(os.Stdin)
	seedText, err := reader.ReadString('\n')
	var seed int64
	if err != nil {
		fmt.Fprintf(os.Stderr, "Can't read seed from stdin! Generating new one...")
		seed = rand.Int63()
	} else {
		seed, err = strconv.ParseInt(seedText, 10, 64)

		if err != nil {
			fmt.Fprintf(os.Stderr, "Can't parse seed from stdin! Generating new one...")
		} else {
			seed = rand.Int63()
		}
	}

	source := rand.NewSource(seed)
	random := rand.New(source)

	err = os.WriteFile(fmt.Sprintf("%d.seed", seed), []byte(fmt.Sprintf("%d\n", seed)), 0644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Can't write the file saving the last seed!")
		panic(err)
	}

	fmt.Fprintf(os.Stderr, "Creating with seed: %d", seed)

	booleans := []string{"true", "false"}
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

	// Generate app users...
	userCount := 6
	fmt.Println("INSERT INTO app_user (email, name, photo_url) VALUES")
	for i := range userCount {
		email := fmt.Sprintf("correo%d@gmail.com", i+1)
		name := from(random, names)
		photo := nullEveryPercent(random, 0.5, from(random, profilePictures))
		fmt.Printf("('%s', '%s', %s)", email, name, photo)

		endInserts(i, userCount)
	}
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
	projectMembers := 2
	fmt.Println("INSERT INTO project_member (project_id, user_id, is_pinned, last_visited) VALUES")
	for pIdx := range projectCount {
		userIdxs := random.Perm(userCount)
		for i := range projectMembers {
			projectId := pIdx + 1
			userId := userIdxs[i] + 1
			isPinned := nullEveryPercent(random, 0.5, from(random, booleans))
			fmt.Printf("(%d, %d, %s, NOW())", projectId, userId, isPinned)

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
			sprint := nullEveryPercent(random, 0.5, random.Intn(10))
			priority := nullEveryPercent(random, 0.8, from(random, taskPriorities))
			fmt.Printf("(%d, '%s', %s, %s, %s, %s, %s)", projectIdx+1, tType, name, dueDate, status, sprint, priority)

			endInserts((projectIdx+1)*(i+1)-1, projectCount*taskCount)
		}
	}

}

func endInserts(i int, count int) {
	if i+1 == count {
		fmt.Print(";")
	} else {
		fmt.Print(",")
	}

	fmt.Println()
}

func nullEveryPercent[T any](r *rand.Rand, percent float32, okValue T) string {
	okMapped := fmt.Sprintf("'%s'", okValue)
	return everyPercent(r, percent, "NULL", okMapped)
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
