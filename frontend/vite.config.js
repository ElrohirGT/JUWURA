import { defineConfig } from "vite";
import elmPlugin from "vite-plugin-elm";
import Unfonts from "unplugin-fonts/vite";

export default defineConfig({
	base: "/JUWURA",
	plugins: [
		elmPlugin({
			debug: false,
		}),

		Unfonts({
			google: {
				families: ["Parkinsans", "IBM Plex Mono"],
			},
		}),
	],
});
