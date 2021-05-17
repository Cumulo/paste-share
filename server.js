
import { main_BANG_, reload_BANG_ } from "./js-out/app.server.js"

main_BANG_()

if (module.hot) {
  module.hot.accept('./js-out/app.server.js', (main) => {
    console.log("Reload server")
    reload_BANG_()
  })
}
