import "./style.css";
import { Elm } from "./Main.elm";

const basePath = import.meta.env.DEV ? null : "JUWURA";

Elm.Main.init({
	flags: basePath,
});
