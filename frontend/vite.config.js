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
				families: ["Parkinsans", "IBM Plex Mono"],
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
});
