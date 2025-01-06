import { defineConfig } from "vite";
import Elm from "vite-plugin-elm";
import Unfonts from "unplugin-fonts/vite";
import Icons from "unplugin-icons/vite";

export default defineConfig({
	base: "/JUWURA",
	plugins: [
		// Auto download and setup google (or others) fonts...
		Unfonts({
			google: {
				families: [
					{
						name: "Parkinsans",
						styles: "wght@300..800",
					},
					{
						name: "IBM Plex Mono",
						styles:
							"ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;1,100;1,200;1,300;1,400;1,500;1,600;1,700",
					},
				],
			},
		}),

		// Get icons
		Icons({
			compiler: "raw",
		}),

		// Use ELM files like any other JS/Asset file...
		Elm({
			debug: false,
		}),
	],
	preview: {
		port: 3001,
	},
	server: {
		port: 3001,
	},
});
