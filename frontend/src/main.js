import './style.css'
import { Elm } from './Main.elm'

const loc = window.location.pathname;
const bPath = loc === "/" ? null : loc.substring(1, 8);
console.log(`The supplied base path is: ${bPath}`)
// Elm.Main.init({
// 	flags: bPath
// });

Elm.Main.init({
	flags: bPath
})
