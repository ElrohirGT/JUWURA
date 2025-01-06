package main

import (
	"bufio"
	"fmt"
	"math/rand"
	"os"
	"slices"
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

	emojis := []string{
		"😀",
		"😋",
		"😎",
		"👺",
		"💩",
		"👽",
		"🤖",
		"😺",
		"😸",
		"😼",
		"🗣",
		"👑",
		"🎩",
		"👙",
	}
	projectBanners := []string{
		"https://img.freepik.com/free-photo/painting-mountain-lake-with-mountain-background_188544-9126.jpg",
		"https://images3.alphacoders.com/135/1350069.jpeg",
		"https://image-0.uhdpaper.com/wallpaper/anime-girl-with-katana-hd-wallpaper-uhdpaper.com-719@0@j.jpg",
		"https://image-0.uhdpaper.com/wallpaper/sports-car-futuristic-mountain-sunset-scenery-digital-art-hd-wallpaper-uhdpaper.com-537@0@i.jpg",
		"https://image-0.uhdpaper.com/wallpaper/anime-girls-angel-wings-hd-wallpaper-uhdpaper.com-187@0@k.jpg",
		"https://image-0.uhdpaper.com/wallpaper/anime-girl-vampire-nun-smoking-hd-wallpaper-uhdpaper.com-608@0@j.jpg",
	}

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
	taskFieldTypes := []string{"TEXT", "DATE", "CHOICE", "NUMBER", "ASSIGNEE"}
	defaultTaskFields := [][]string{
		{"TEXT", "Title"},
		{"DATE", "Due Date"},
		{"CHOICE", "Status"},
		{"CHOICE", "Priority"},
		{"NUMBER", "Sprint"},
		{"ASSIGNEE", "Assignees"},
		{"TEXT", "Description"},
	}

	// Changing to DB...
	fmt.Println("\\c juwura")

	// Generate app users...
	userCount := 8
	generatedEmails := make([]string, userCount)
	fmt.Println("INSERT INTO app_user (email, name, photo_url) VALUES")
	for i := range userCount {
		email := fmt.Sprintf("correo%d@gmail.com", i+1)
		name := from(random, names)
		photo := from(random, profilePictures)
		fmt.Printf("('%s', '%s', '%s')", email, name, photo)

		generatedEmails[i] = email
		endInserts(i, userCount)
	}
	// fmt.Fprintln(os.Stderr, generatedEmails)
	fmt.Println()

	// Generate projects...
	projectCount := 5
	fmt.Println("INSERT INTO project (name, photo_url, icon, owner, next_task_id) VALUES")
	for i := range projectCount {
		name := fmt.Sprintf("Proyecto %s", from(random, names))
		photo := from(random, projectBanners)
		icon := from(random, emojis)
		owner := from(random, generatedEmails)
		fmt.Printf("('%s', '%s', '%s', '%s', DEFAULT)", name, photo, icon, owner)

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

	// Generate task field types...
	fmt.Println("INSERT INTO task_field_type (name, project_id) VALUES")
	for projecIdx := range projectCount {
		projectId := projecIdx + 1

		for idx, name := range taskFieldTypes {
			fmt.Printf("('%s', %d)", name, projectId)

			endInserts((idx+1)*(projecIdx+1)-1, projectCount*len(taskFieldTypes))
		}
	}
	fmt.Println()

	// Generate custom task fields...
	fmt.Println("INSERT INTO task_field (project_id, task_field_type_id, name) VALUES")
	for projecIdx := range projectCount {
		projectId := projecIdx + 1

		for taskFieldIdx, taskFieldInfo := range defaultTaskFields {
			i := slices.Index(taskFieldTypes, taskFieldInfo[0])
			taskFieldTypeId := i + 1 + projecIdx*len(taskFieldTypes)
			taskFieldName := taskFieldInfo[1]

			fmt.Printf("(%d, %d, '%s')", projectId, taskFieldTypeId, taskFieldName)
			endInserts((projecIdx+1)*(taskFieldIdx+1)-1, projectCount*len(defaultTaskFields))
		}
	}
	fmt.Println()

	// Generate custom task field options...
	fmt.Println("INSERT INTO task_field_option (task_field, value) VALUES")
	for projecIdx := range projectCount {
		taskFieldId := projecIdx*3 + 3

		for _, status := range taskStatuses {
			fmt.Printf("(%d, '%s')", taskFieldId, status)
			fmt.Println(",")
		}

		for i, priority := range taskPriorities {
			fmt.Printf("(%d, '%s')", taskFieldId, priority)
			if i+1 == len(taskPriorities) && projecIdx+1 == projectCount {
				fmt.Println(";")
			} else {
				fmt.Println(",")
			}
		}

	}
	fmt.Println()

	// Generate tasks...
	taskCount := 10
	fmt.Println("INSERT INTO task (project_id, parent_id, display_id, icon, senku_row, senku_column) VALUES")
	for projectIdx := range projectCount {
		for i := range taskCount {
			projectId := projectIdx + 1
			parentId := "NULL"
			if i != 0 {
				parentId = nullEveryPercent(random, 0.5, fmt.Sprintf("%d", random.Intn(i)+1+projectIdx*taskCount))
			}
			shortTitle := fmt.Sprintf("T-%d", i+1)
			icon := from(random, emojis)
			fmt.Printf("(%d, %s, '%s', '%s', DEFAULT, DEFAULT)", projectId, parentId, shortTitle, icon)

			endInserts((projectIdx+1)*(i+1)-1, projectCount*taskCount)
		}
	}
	fmt.Println()

	// Populate tasks randomly...
	fmt.Println("INSERT INTO task_fields_for_task (task_id, task_field_id, value) VALUES")
	for projectIdx := range projectCount {
		for taskIdx := range taskCount {
			taskId := taskIdx + 1 + projectIdx*taskCount

			for i := range defaultTaskFields {
				taskFieldId := i + 1 + len(defaultTaskFields)*projectIdx
				value := "NULL"
				switch i {
				case 0:
					okValue := fmt.Sprintf("'%s'", from(random, taskNames))
					value = nullEveryPercent(random, 0.5, okValue)
				case 1:
					okValue := fmt.Sprintf("NOW() + interval '%d day'", random.Intn(20))
					value = nullEveryPercent(random, 0.5, okValue)
				case 2:
					okValue := fmt.Sprintf("'%s'", from(random, taskStatuses))
					value = nullEveryPercent(random, 0.5, okValue)
				case 3:
					okValue := fmt.Sprintf("'%s'", from(random, taskPriorities))
					value = nullEveryPercent(random, 0.5, okValue)
				case 4:
					okValue := fmt.Sprintf("%d", random.Intn(15)+1)
					value = nullEveryPercent(random, 0.5, okValue)
				case 5:
					okValue := fmt.Sprintf("'[\"%s\"]'", from(random, membersByProject[projectIdx]))
					value = nullEveryPercent(random, 0.5, okValue)
				case 6:
					okValue := fmt.Sprintf("'%s'", "This is a test description!")
					value = nullEveryPercent(random, 0.5, okValue)
				}
				fmt.Printf("(%d, %d, %s)", taskId, taskFieldId, value)

				if projectIdx+1 == projectCount && taskIdx+1 == taskCount && i+1 == len(defaultTaskFields) {
					fmt.Println(";")
				} else {
					fmt.Println(",")
				}
			}
		}
	}
	fmt.Println()

	// Generate tasks unblocks...
	fmt.Println("INSERT INTO task_connection (target_task, unblocked_task) VALUES")
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
}

func endInserts(i int, count int) {
	if i+1 == count {
		fmt.Println(";")
	} else {
		fmt.Println(",")
	}
}

func nullEveryPercent(r *rand.Rand, percent float32, okValue string) string {
	okMapped := fmt.Sprintf("%s", okValue)
	return everyPercent(r, percent, "NULL", okMapped)
}

func defaultEveryPercent(r *rand.Rand, percent float32, okValue string) string {
	okMapped := fmt.Sprintf("%s", okValue)
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
