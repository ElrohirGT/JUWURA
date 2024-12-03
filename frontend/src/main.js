import "./style.css";
import { Elm } from "./Main.elm";

// NOTE: We need to use substring to remove the / at the beginning
const basePath = import.meta.env.BASE_URL.substring(1);

Elm.Main.init({
	flags: basePath,
});
