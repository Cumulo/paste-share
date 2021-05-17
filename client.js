
import { main_BANG_ } from "./out-page/app.client.js"

main_BANG_()

if (import.meta.hot) {
  import.meta.hot.accept('./out-page/app.client.js', (main) => {
    main.reload_BANG_()
  })
}
