
{} (:package |app)
  :configs $ {} (:init-fn |app.server/main!) (:reload-fn |app.server/reload!)
    :modules $ [] |respo.calcit/ |lilac/ |recollect/ |memof/ |respo-ui.calcit/ |ws-edn.calcit/ |cumulo-util.calcit/ |respo-message.calcit/ |cumulo-reel.calcit/ |respo-feather.calcit/ |alerts.calcit/
    :version nil
  :files $ {}
    |app.comp.snippet $ {}
      :ns $ quote
        ns app.comp.snippet $ :require
          respo.util.format :refer $ hsl
          app.schema :as schema
          respo-ui.core :as ui
          respo.core :refer $ defcomp list-> <> >> span div button textarea a defeffect create-element
          respo.comp.space :refer $ =<
          app.config :as config
          feather.core :refer $ comp-icon
          respo-alerts.core :refer $ use-prompt use-modal use-confirm
          "\"dayjs" :default dayjs
          feather.core :refer $ comp-icon comp-i
          "\"copy-text-to-clipboard" :default copy!
          "\"qrcode" :as QRCode
      :defs $ {}
        |comp-qrcode $ quote
          defcomp comp-qrcode (content on-close)
            [] (effect-code content)
              div
                {} $ :style
                  merge ui/center $ {} (:padding 40)
                div ({})
                  <> $ js/JSON.stringify content
                create-element :canvas $ {}
        |comp-snippet $ quote
          defcomp comp-snippet (states snippet)
            let
                cursor $ :cursor states
                state $ either (:data states)
                  {} $ :copied? false
                qrcode-plugin $ use-modal (>> states :qrcode)
                  {} (:title "\"QR Code")
                    :render $ fn (on-close)
                      comp-qrcode (:content snippet) on-close
                desc-plugin $ use-prompt (>> states :desc)
                  {} (:title "\"Description") (:multiline? true)
                    :initial $ :desc snippet
                delete-plugin $ use-confirm (>> states :remove)
                  {} $ :text "\"Sure to remove?"
              div
                {} $ :style style-snippet
                div
                  {} $ :style ui/row-parted
                  let
                      content $ either (:content snippet) "\"..."
                    div
                      {} $ :style ui/row-middle
                      if
                        and
                          or (starts-with? content "\"http://") (starts-with? content "\"https://")
                          not $ includes? (trim content) "\" "
                        a $ {}
                          :href $ trim content
                          :inner-text content
                          :target "\"_blank"
                        <> content
                      =< 16 nil
                      comp-icon :copy
                        merge style-icon $ {}
                          :color $ hsl 200 20 60 0.5
                        fn (e d!)
                          copy! $ :content snippet
                          d! cursor $ assoc state :copied? true
                          js/setTimeout
                            fn () $ d! cursor (assoc state :copied? false)
                            , 2000
                      =< 16 nil
                      comp-icon :camera
                        merge style-icon $ {}
                          :color $ hsl 200 20 60 0.5
                        fn (e d!) (.show qrcode-plugin d!)
                      =< 16 nil
                      div
                        {} (:style ui/row-middle)
                          :on-click $ fn (e d!)
                            d! :router/change $ {} (:name :snippet)
                              :id $ :id snippet
                        comp-icon :message-square style-icon nil
                        =< 4 0
                        <> $ .count (:replies snippet)
                  comp-icon :x
                    merge style-icon $ {}
                      :color $ hsl 0 80 60
                    fn (e d!)
                      .show delete-plugin d! $ fn ()
                        d! :snippet/remove $ :id snippet
                div
                  {} $ :style ui/row-parted
                  div
                    {} $ :style ui/row-middle
                    <> $ &let
                      desc $ :desc snippet
                      if
                        and (some? desc)
                          not $ .blank? desc
                        , desc "\"..."
                    =< 8 nil
                    comp-icon :edit (merge style-icon)
                      fn (e d!)
                        .show desc-plugin d! $ fn (value)
                          when
                            and (some? value)
                              not $ .blank? value
                            d! :snippet/update $ [] (:id snippet)
                              {} $ :desc value
                  div ({})
                    <> $ str "\"by "
                      either (:nickname snippet) "\"??"
                    =< 8 nil
                    <>
                      -> (:time snippet) (dayjs) (.format "\"HH:mm")
                      {} $ :color (hsl 0 0 90)
                if (:copied? state) template-copied
                .render qrcode-plugin
                .render desc-plugin
                .render delete-plugin
        |effect-code $ quote
          defeffect effect-code (content) (action el)
            when (= action :mount)
              let
                  target $ js/document.querySelector "\"canvas"
                if (some? target)
                  QRCode/toCanvas target content $ fn (e ? el2)
                    if (some? e) (js/console.error e)
                  js/console.error "\"missing canvas element"
        |style-icon $ quote
          def style-icon $ {}
            :color $ hsl 200 20 60 0.5
            :font-size 14
            :cursor :pointer
        |style-snippet $ quote
          def style-snippet $ {}
            :border $ str "\"1px solid " (hsl 0 0 90)
            :padding "\"2px 8px"
            :margin "\"8px 0"
            :border-radius "\"8px"
            :position :relative
        |template-copied $ quote
          def template-copied $ div
            {} $ :style
              merge ui/center $ {} (:position :absolute) (:top 10) (:left 10)
                :background-color $ hsl 0 0 0 0.6
                :color :white
                :padding "\"0 8px"
                :border-radius "\"2px"
                :font-size 12
                :font-family ui/font-fancy
            <> "\"Copied"
      :proc $ quote ()
      :configs $ {}
    |app.updater.user $ {}
      :ns $ quote
        ns app.updater.user $ :require
          [] cumulo-util.core :refer $ [] find-first
          [] "\"md5" :as md5
      :defs $ {}
        |log-in $ quote
          defn log-in (db op-data sid op-id op-time)
            let-sugar
                  [] username password
                  , op-data
                maybe-user $ -> (:users db) (vals) (set->list)
                  find $ fn (user)
                    and $ = username (:name user)
              update-in db ([] :sessions sid)
                fn (session)
                  if (some? maybe-user)
                    if
                      = (md5/@ password) (:password maybe-user)
                      assoc session :user-id $ :id maybe-user
                      update session :messages $ fn (messages)
                        assoc messages op-id $ {} (:id op-id)
                          :text $ str "\"Wrong password for " username
                    update session :messages $ fn (messages)
                      assoc messages op-id $ {} (:id op-id)
                        :text $ str "\"No user named: " username
        |log-out $ quote
          defn log-out (db op-data sid op-id op-time)
            assoc-in db ([] :sessions sid :user-id) nil
        |sign-up $ quote
          defn sign-up (db op-data sid op-id op-time)
            let-sugar
                  [] username password
                  , op-data
                maybe-user $ find
                  vals $ :users db
                  fn (user)
                    = username $ :name user
              if (some? maybe-user)
                update-in db ([] :sessions sid :messages)
                  fn (messages)
                    assoc messages op-id $ {} (:id op-id)
                      :text $ str "\"Name is taken: " username
                -> db
                  assoc-in ([] :sessions sid :user-id) op-id
                  assoc-in ([] :users op-id)
                    {} (:id op-id) (:name username) (:nickname username)
                      :password $ md5/@ password
                      :avatar nil
      :proc $ quote ()
    |app.updater.router $ {}
      :ns $ quote (ns app.updater.router)
      :defs $ {}
        |change $ quote
          defn change (db op-data sid op-id op-time)
            assoc-in db ([] :sessions sid :router) op-data
      :proc $ quote ()
    |app.comp.login $ {}
      :ns $ quote
        ns app.comp.login $ :require
          [] respo.core :refer $ [] defcomp <> div input button span
          [] respo.comp.space :refer $ [] =<
          [] respo.comp.inspect :refer $ [] comp-inspect
          [] respo-ui.core :as ui
          [] app.schema :as schema
          [] app.config :as config
      :defs $ {}
        |comp-login $ quote
          defcomp comp-login (states)
            let
                cursor $ :cursor states
                state $ or (:data states) initial-state
              div
                {} $ :style (merge ui/flex ui/center)
                div ({})
                  div
                    {} $ :style ({})
                    div ({})
                      input $ {} (:placeholder "\"Username")
                        :value $ :username state
                        :style ui/input
                        :on-input $ fn (e d!)
                          d! cursor $ assoc state :username (:value e)
                    =< nil 8
                    div ({})
                      input $ {} (:placeholder "\"Password")
                        :value $ :password state
                        :style ui/input
                        :on-input $ fn (e d!)
                          d! cursor $ assoc state :password (:value e)
                  =< nil 8
                  div
                    {} $ :style
                      {} $ :text-align :right
                    span $ {} (:inner-text "\"Sign up")
                      :style $ merge ui/link
                      :on-click $ on-submit (:username state) (:password state) true
                    =< 8 nil
                    span $ {} (:inner-text "\"Log in")
                      :style $ merge ui/link
                      :on-click $ on-submit (:username state) (:password state) false
        |initial-state $ quote
          def initial-state $ {} (:username "\"") (:password "\"")
        |on-submit $ quote
          defn on-submit (username password signup?)
            fn (e dispatch!)
              dispatch! (if signup? :user/sign-up :user/log-in) ([] username password)
              .setItem js/localStorage (:storage-key config/site)
                write-cirru-edn $ [] username password
      :proc $ quote ()
    |app.updater.session $ {}
      :ns $ quote
        ns app.updater.session $ :require ([] app.schema :as schema)
      :defs $ {}
        |connect $ quote
          defn connect (db op-data sid op-id op-time)
            assoc-in db ([] :sessions sid)
              merge schema/session $ {} (:id sid) (:nickname sid)
        |disconnect $ quote
          defn disconnect (db op-data sid op-id op-time)
            update db :sessions $ fn (session) (dissoc session sid)
        |remove-message $ quote
          defn remove-message (db op-data sid op-id op-time)
            update-in db ([] :sessions sid :messages)
              fn (messages)
                dissoc messages $ :id op-data
        |nickname $ quote
          defn nickname (db op-data sid op-id op-time)
            assoc-in db ([] :sessions sid :nickname) op-data
      :proc $ quote ()
    |app.comp.snippet-detail $ {}
      :ns $ quote
        ns app.comp.snippet-detail $ :require
          respo.util.format :refer $ hsl
          app.schema :as schema
          respo-ui.core :as ui
          respo.core :refer $ defcomp list-> <> >> span div button textarea a defeffect create-element
          respo.comp.space :refer $ =<
          app.config :as config
          feather.core :refer $ comp-icon
          respo-alerts.core :refer $ use-prompt use-modal use-confirm
          "\"dayjs" :default dayjs
          feather.core :refer $ comp-icon
          "\"copy-text-to-clipboard" :default copy!
          "\"qrcode" :as QRCode
          app.comp.snippet :refer $ comp-snippet
          [] app.comp.message-box :refer $ [] comp-message-box
      :defs $ {}
        |comp-snippet-detail $ quote
          defcomp comp-snippet-detail (states snippet)
            let
                clear-plugin $ use-confirm (>> states :clear)
                  {} $ :text "\"clear?"
              div
                {} $ :style
                  merge ui/expand ui/column $ {} (:position :relative)
                comp-snippet (>> states :preview) snippet
                div
                  {} $ :style
                    merge ui/expand $ {}
                  list-> ({})
                    -> (:replies snippet) (to-pairs) (.to-list) (map last)
                      sort $ fn (a b)
                        - (:time a) (:time b)
                      map $ fn (reply)
                        [] (:id reply)
                          div
                            {} $ :style
                              {}
                                :border $ str "\"1px solid " (hsl 0 0 90)
                                :margin "\"4px 0"
                                :padding 8
                                :border-radius "\"8px"
                            div ({})
                              <> $ :content reply
                            div ({}) (<> "\"by") (=< 4 nil)
                              <> $ :nickname reply
                              =< 8 nil
                              <>
                                -> (:time snippet) (dayjs) (.format "\"HH:mm")
                                {} $ :color (hsl 0 0 90)
                  if (-> snippet :replies empty?)
                    div
                      {} $ :style ui/center
                      <> "\"No replies" $ {}
                        :color $ hsl 0 0 80
                        :font-family ui/font-fancy
                  div $ {}
                    :style $ {} (:height "\"70%")
                div
                  {} $ :style ui/row-parted
                  span $ {}
                  a $ {} (:style ui/link) (:inner-text "\"Clear")
                    :on-click $ fn (e d!)
                        :show clear-plugin
                        , d! $ fn ()
                          d! :snippet/clear-replies $ :id snippet
                comp-message-box (>> states :message)
                  fn (content d!)
                    d! :snippet/reply $ [] (:id snippet) content
                  {} $ :placeholder "\"reply to this..."
                .render clear-plugin
        |comp-reply $ quote
          defcomp comp-reply (reply)
            div ({}) (<> "\"This is a faked reply")
      :proc $ quote ()
      :configs $ {}
    |app.schema $ {}
      :ns $ quote (ns app.schema)
      :defs $ {}
        |database $ quote
          def database $ {}
            :sessions $ do session ({})
            :snippets $ do snippet ({})
        |router $ quote
          def router $ {} (:name nil) (:title nil)
            :data $ {}
            :router nil
        |session $ quote
          def session $ {} (:id nil) (:nickname nil)
            :router $ do router
              {} (:name :home) (:data nil) (:router nil)
            :messages $ {}
        |snippet $ quote
          def snippet $ {} (:id nil) (:time nil) (:nickname nil) (:content nil) (:desc "\"")
            :replies $ do reply ({})
        |reply $ quote
          def reply $ {} (:id nil) (:nickname nil) (:time nil) (:content "\"")
      :proc $ quote ()
    |app.updater $ {}
      :ns $ quote
        ns app.updater $ :require ([] app.updater.session :as session) ([] app.updater.router :as router) (app.updater.snippet :as snippet) ([] app.schema :as schema)
          [] respo-message.updater :refer $ [] update-messages
      :defs $ {}
        |updater $ quote
          defn updater (db op op-data sid op-id op-time)
            let
                session $ get-in db ([] :sessions sid)
                f $ case-default op
                  fn (& args)
                    do (println "\"Unknown op:" op) db
                  :session/connect session/connect
                  :session/disconnect session/disconnect
                  :session/remove-message session/remove-message
                  :session/nickname session/nickname
                  :snippet/create snippet/create-snippet
                  :snippet/remove snippet/remove-snippet
                  :snippet/update snippet/update-snippet
                  :snippet/reply snippet/add-reply
                  :snippet/clear-replies snippet/clear-replies
                  :router/change router/change
              f db op-data sid op-id op-time
      :proc $ quote ()
    |app.config $ {}
      :ns $ quote (ns app.config)
      :defs $ {}
        |cdn? $ quote
          def cdn? $ cond
              exists? js/window
              , false
            (exists? js/process) (= "\"true" js/process.env.cdn)
            true false
        |dev? $ quote
          def dev? $ = "\"dev" (get-env "\"mode")
        |site $ quote
          def site $ {} (:port 11025) (:title "\"Paste Sharing") (:icon "\"http://cdn.tiye.me/logo/cumulo.png") (:dev-ui "\"http://localhost:8100/main.css") (:release-ui "\"http://cdn.tiye.me/favored-fonts/main.css") (:cdn-url "\"http://cdn.tiye.me/paste-sharing/") (:theme "\"#eeeeff") (:storage-key "\"paste-sharing") (:storage-file "\"storage.cirru")
      :proc $ quote ()
    |app.client $ {}
      :ns $ quote
        ns app.client $ :require
          [] respo.core :refer $ [] render! clear-cache! realize-ssr!
          [] respo.cursor :refer $ [] update-states
          [] app.comp.container :refer $ [] comp-container
          [] app.schema :as schema
          [] app.config :as config
          [] ws-edn.client :refer $ [] ws-connect! ws-send!
          [] recollect.patch :refer $ [] patch-twig
          [] cumulo-util.core :refer $ [] on-page-touch
          "\"url-parse" :default url-parse
      :defs $ {}
        |ssr? $ quote
          def ssr? $ some? (.querySelector js/document "\"meta.respo-ssr")
        |dispatch! $ quote
          defn dispatch! (op op-data)
            when
              and config/dev? $ not= op :states
              println "\"Dispatch" op op-data
            case op
              :states $ reset! *states (update-states @*states op-data)
              :effect/connect $ connect!
              op $ ws-send!
                {} (:kind :op) (:op op) (:data op-data)
        |*store $ quote (defatom *store nil)
        |main! $ quote
          defn main! () (load-console-formatter!)
            println "\"Running mode:" $ if config/dev? "\"dev" "\"release"
            if ssr? $ render-app! realize-ssr!
            render-app! render!
            connect!
            add-watch *store :changes $ fn (store prev) (render-app! render!)
            add-watch *states :changes $ fn (states prev) (render-app! render!)
            on-page-touch $ fn ()
              if (nil? @*store) (connect!)
            println "\"App started!"
        |*states $ quote
          defatom *states $ {}
            :states $ {}
              :cursor $ []
        |connect! $ quote
          defn connect! () $ let
              url-obj $ url-parse js/location.href true
              host $ or (; -> url-obj .-query .-host) js/location.hostname
              port $ or (; -> url-obj .-query .-port) (:port config/site)
            ws-connect! (str "\"ws://" host "\":" port)
              {}
                :on-open $ fn (event) (js/console.info "\"connection established")
                :on-close $ fn (event) (reset! *store nil) (js/console.error "\"Lost connection!")
                :on-data $ fn (data)
                  case (:kind data)
                    :patch $ let
                        changes $ :data data
                      when config/dev? $ js/console.log "\"Changes" changes
                      reset! *store $ patch-twig @*store changes
                    (:kind data) (println "\"unknown kind:" data)
        |render-app! $ quote
          defn render-app! (renderer)
            renderer mount-target
              comp-container (:states @*states) @*store
              , dispatch!
        |reload! $ quote
          defn reload! () (remove-watch *store :changes) (remove-watch *store :changes) (clear-cache!) (render-app! render!)
            add-watch *store :changes $ fn (store prev) (render-app! render!)
            add-watch *states :changes $ fn (states prev) (render-app! render!)
            println "\"Code updated."
        |mount-target $ quote
          def mount-target $ .querySelector js/document "\".app"
      :proc $ quote ()
    |app.comp.navigation $ {}
      :ns $ quote
        ns app.comp.navigation $ :require
          [] respo.util.format :refer $ [] hsl
          [] respo-ui.core :as ui
          [] respo.comp.space :refer $ [] =<
          [] respo.core :refer $ [] defcomp <> span div
          [] app.config :as config
      :defs $ {}
        |comp-navigation $ quote
          defcomp comp-navigation (nickname count-members)
            div
              {} $ :style
                merge ui/row-center $ {} (:height "\"40px") (:justify-content :space-between) (:padding "\"0 16px") (:font-size 16)
                  :border-bottom $ str "\"1px solid " (hsl 0 0 0 0.1)
                  :font-family ui/font-fancy
              div
                {}
                  :on-click $ fn (e d!)
                    d! :router/change $ {} (:name :home)
                  :style $ {} (:cursor :pointer)
                <> (:title config/site) nil
              div
                {}
                  :style $ {} (:cursor "\"pointer")
                  :on-click $ fn (e d!)
                    d! :router/change $ {} (:name :profile)
                <> nickname
                =< 8 nil
                <> count-members
      :proc $ quote ()
    |app.comp.message-box $ {}
      :ns $ quote
        ns app.comp.message-box $ :require
          respo.util.format :refer $ hsl
          app.schema :as schema
          respo-ui.core :as ui
          respo.core :refer $ defcomp list-> <> >> span div button textarea a defeffect create-element
          respo.comp.space :refer $ =<
          app.config :as config
          feather.core :refer $ comp-icon
      :defs $ {}
        |comp-message-box $ quote
          defcomp comp-message-box (states on-submit options)
            let
                cursor $ :cursor states
                state $ either (:data states)
                  {} $ :text "\""
                submit! $ fn (d!)
                  when
                    not $ blank? (:text state)
                    on-submit (:text state) d!
                    d! cursor $ assoc state :text "\""
              div
                {} $ :style ui/row
                textarea $ {}
                  :style $ merge ui/expand ui/textarea
                  :placeholder $ :placeholder options
                  :value $ :text state
                  :on-input $ fn (e d!)
                    d! cursor $ assoc state :text (:value e)
                  :on-keydown $ fn (e d!)
                    &let
                      event $ :event e
                      when
                        and
                          = "\"Enter" $ .-key event
                          not $ or (.-shiftKey event) (.-ctrlKey event)
                        .!preventDefault event
                        submit! d!
                =< 8 nil
                div ({})
                  button $ {} (:style ui/button) (:inner-text "\"Send")
                    :on-click $ fn (e d!) (submit! d!)
      :proc $ quote ()
      :configs $ {}
    |app.comp.container $ {}
      :ns $ quote
        ns app.comp.container $ :require
          [] hsl.core :refer $ [] hsl
          [] respo-ui.core :as ui
          [] respo.core :refer $ [] defcomp <> >> div span button input pre
          [] respo.comp.inspect :refer $ [] comp-inspect
          [] respo.comp.space :refer $ [] =<
          [] app.comp.navigation :refer $ [] comp-navigation
          [] app.comp.profile :refer $ [] comp-profile
          [] app.comp.login :refer $ [] comp-login
          [] respo-message.comp.messages :refer $ [] comp-messages
          [] cumulo-reel.comp.reel :refer $ [] comp-reel
          [] app.config :refer $ [] dev?
          [] app.schema :as schema
          [] app.config :as config
          respo.util.format :refer $ hsl
          app.comp.home :refer $ comp-home
          app.comp.snippet-detail :refer $ comp-snippet-detail
      :defs $ {}
        |comp-container $ quote
          defcomp comp-container (states store)
            let
                state $ either (:data states)
                  {} $ :demo "\""
                session $ :session
                  either store $ {}
                router $ either
                  :router $ either store ({})
                  {}
                router-data $ :data router
              if (nil? store) (comp-offline)
                div
                  {} $ :style (merge ui/global ui/fullscreen ui/column)
                  comp-navigation (:nickname session) (:count store)
                  div
                    {} $ :style
                      merge ui/expand ui/row $ {} (:padding "\"0 80px")
                    case-default (:name router)
                      <> $ str "\"Unknown page: " router
                      :home $ comp-home (>> states :home) (:snippets store)
                      :profile $ comp-profile (>> states :profile) (:nickname session)
                      :snippet $ comp-snippet-detail (>> states :detail) (:snippet router-data)
                  comp-status-color $ :color store
                  when dev? $ comp-inspect "\"Store" store
                    {} (:bottom 0) (:left 0) (:max-width "\"100%")
                  comp-messages
                    get-in store $ [] :session :messages
                    {}
                    fn (info d!) (d! :session/remove-message info)
                  when dev? $ comp-reel (:reel-length store) ({})
        |comp-offline $ quote
          defcomp comp-offline () $ div
            {} $ :style
              merge ui/global ui/fullscreen ui/column-dispersive $ {}
                :background-color $ :theme config/site
            div $ {}
              :style $ {} (:height 0)
            div $ {}
              :style $ {}
                :background-image $ str "\"url(" (:icon config/site) "\")"
                :width 128
                :height 128
                :background-size :contain
            div
              {}
                :style $ {} (:cursor :pointer) (:line-height "\"32px")
                :on-click $ fn (e d!) (d! :effect/connect nil)
              <> "\"No connection..." $ {} (:font-family ui/font-fancy) (:font-size 24)
        |comp-status-color $ quote
          defcomp comp-status-color (color)
            div $ {}
              :style $ let
                  size 24
                {} (:width size) (:height size) (:position :absolute) (:bottom 60) (:left 8) (:background-color color) (:border-radius "\"50%") (:opacity 0.6) (:pointer-events :none)
      :proc $ quote ()
    |app.comp.home $ {}
      :ns $ quote
        ns app.comp.home $ :require
          respo.util.format :refer $ hsl
          app.schema :as schema
          respo-ui.core :as ui
          respo.core :refer $ defcomp list-> <> >> span div button textarea a defeffect create-element
          respo.comp.space :refer $ =<
          app.config :as config
          feather.core :refer $ comp-icon
          respo-alerts.core :refer $ use-prompt use-modal
          "\"dayjs" :default dayjs
          feather.core :refer $ comp-icon
          "\"copy-text-to-clipboard" :default copy!
          "\"qrcode" :as QRCode
          app.comp.snippet :refer $ [] comp-snippet
          [] app.comp.message-box :refer $ [] comp-message-box
      :defs $ {}
        |comp-home $ quote
          defcomp comp-home (states snippets)
            let
                cursor $ :cursor states
                state $ either (:data states)
                  {} $ :text "\""
                submit! $ fn (d!)
                  when
                    not $ blank? (:text state)
                    d! :snippet/create $ trim (:text state)
                    d! cursor $ assoc state :text "\""
              div
                {} $ :style
                  merge ui/column $ {} (:padding "\"8px 0") (:width "\"100%")
                comp-message-box (>> states :box)
                  fn (content d!) (d! :snippet/create content)
                  {} $ :placeholder "\"Paste a link... and press Enter"
                =< nil 8
                div
                  {} $ :style
                    merge ui/expand $ {} (:padding-bottom 200)
                  , &
                    -> snippets (vals) (.to-list)
                      sort $ fn (a b)
                        - (:time b) (:time a)
                      map $ fn (snippet)
                        comp-snippet
                          >> states $ :id snippet
                          , snippet
                    if (empty? snippets)
                      div
                        {} $ :style ui/center
                        <> "\"All Cleared." $ {}
                          :color $ hsl 0 0 70
                          :font-family ui/font-fancy
                          :padding "\"16px 0"
                          :font-size 16
                          :font-style :italic
      :proc $ quote ()
      :configs $ {}
    |app.updater.snippet $ {}
      :ns $ quote
        ns app.updater.snippet $ :require (app.schema :as schema)
      :defs $ {}
        |create-snippet $ quote
          defn create-snippet (db op-data sid op-id op-time)
            let
                session $ get-in db ([] :sessions sid)
              assoc-in db ([] :snippets op-id)
                merge schema/snippet $ {} (:id op-id) (:time op-time) (:content op-data)
                  :nickname $ get session :nickname
        |remove-snippet $ quote
          defn remove-snippet (db op-data sid op-id op-time)
            let
                session $ get-in db ([] :sessions sid)
              update db :snippets $ fn (s) (dissoc s op-data)
        |update-snippet $ quote
          defn update-snippet (db op-data sid op-id op-time)
            let
                session $ get-in db ([] :sessions sid)
              let[] (s-id changes) op-data $ update-in db ([] :snippets s-id)
                fn (snippet)
                  merge snippet $ dissoc changes :id
        |add-reply $ quote
          defn add-reply (db op-data sid op-id op-time)
            let
                session $ get-in db ([] :sessions sid)
              let[] (s-id content) op-data $ update-in db ([] :snippets s-id :replies)
                fn (replies)
                  if (some? replies)
                    assoc replies op-id $ merge schema/reply
                      {} (:id op-id) (:content content)
                        :nickname $ :nickname session
                        :time op-time
        |clear-replies $ quote
          defn clear-replies (db op-data sid op-id op-time)
            update-in db ([] :snippets op-data)
              fn (snippet)
                if (some? snippet)
                  assoc snippet :replies $ {}
                  println "\"[error] found no snippet with id:" op-data
      :proc $ quote ()
      :configs $ {}
    |app.comp.profile $ {}
      :ns $ quote
        ns app.comp.profile $ :require
          respo.util.format :refer $ hsl
          app.schema :as schema
          respo-ui.core :as ui
          respo.core :refer $ defcomp list-> <> >> span div button
          respo.comp.space :refer $ =<
          app.config :as config
          feather.core :refer $ comp-icon
          respo-alerts.core :refer $ use-prompt
      :defs $ {}
        |comp-profile $ quote
          defcomp comp-profile (states nickname)
            let
                name-plugin $ use-prompt (>> states :name)
                  {} (:text "\"Set name") (:initial nickname)
              div
                {} $ :style
                  merge ui/flex $ {} (:padding 16)
                div
                  {} $ :style ({})
                  <> (str "\"Hello!")
                    {} (:font-family ui/font-fancy) (:font-size 32) (:font-weight 100)
                  =< 16 nil
                  <> nickname $ {} (:font-weight "\"bold") (:font-size 24)
                  =< 8 nil
                  comp-icon :edit
                    {} (:font-size 14)
                      :color $ hsl 0 0 80
                      :cursor :pointer
                    fn (e d!)
                        :show name-plugin
                        , d! $ fn (text)
                          when
                            not $ blank? text
                            d! :session/nickname text
                :ui name-plugin
      :proc $ quote ()
    |app.twig.container $ {}
      :ns $ quote
        ns app.twig.container $ :require
          [] app.twig.user :refer $ [] twig-user
          [] "\"randomcolor" :as color
          [] memof.alias :refer $ [] memof-call
      :defs $ {}
        |twig-container $ quote
          defn twig-container (db session records)
            let
                router $ :router session
                base-data $ {} (:session session)
                  :reel-length $ count records
              merge base-data $ {}
                :router $ assoc router :data
                  case-default (:name router) ({})
                    :home $ :pages db
                    :snippet $ let
                        s-id $ -> router :id
                        snippet $ if (some? s-id)
                          get-in db $ [] :snippets s-id
                      {} $ :snippet snippet
                    :profile $ {}
                :count $ count (:sessions db)
                :color $ color/randomColor
                :snippets $ :snippets db
      :proc $ quote ()
    |app.server $ {}
      :ns $ quote
        ns app.server $ :require ([] app.schema :as schema)
          [] app.updater :refer $ [] updater
          [] cljs.reader :refer $ [] read-string
          [] cumulo-reel.core :refer $ [] reel-reducer refresh-reel reel-schema
          [] "\"fs" :as fs
          [] "\"path" :as path
          [] app.config :as config
          [] cumulo-util.file :refer $ [] write-mildly! get-backup-path! merge-local-edn!
          [] cumulo-util.core :refer $ [] id! repeat! unix-time! delay!
          [] app.twig.container :refer $ [] twig-container
          [] recollect.diff :refer $ [] diff-twig
          [] ws-edn.server :refer $ [] wss-serve! wss-send! wss-each!
          [] recollect.twig :refer $ [] new-twig-loop! clear-twig-caches!
      :defs $ {}
        |dispatch! $ quote
          defn dispatch! (op op-data sid)
            let
                op-id $ id!
                op-time $ unix-time!
              if config/dev? $ println "\"Dispatch!" (str op) op-data sid
              cond
                  = op :effect/persist
                  persist-db!
                true $ reset! *reel (reel-reducer @*reel @*proxied-updater op op-data sid op-id op-time config/dev?)
        |main! $ quote
          defn main! ()
            println "\"Running mode:" $ if config/dev? "\"dev" "\"release"
            let
                port $ if (some? js/process.env.port) (js/parseInt js/process.env.port) (:port config/site)
              run-server! port
              println $ str "\"Server started on port:" port
            render-loop! *loop-trigger
            js/process.on "\"SIGINT" on-exit!
            repeat! 600 $ fn () (persist-db!)
        |*loop-trigger $ quote (defatom *loop-trigger 0)
        |run-server! $ quote
          defn run-server! (port)
            wss-serve! port $ {}
              :on-open $ fn (sid socket) (dispatch! :session/connect nil sid) (js/console.info "\"New client.")
              :on-data $ fn (sid action)
                case (:kind action)
                  :op $ dispatch! (:op action) (:data action) sid
                  (:kind action) (println "\"unknown data" action)
              :on-close $ fn (sid event) (js/console.warn "\"Client closed!") (dispatch! :session/disconnect nil sid)
              :on-error $ fn (error) (.error js/console error)
        |sync-clients! $ quote
          defn sync-clients! (reel)
            wss-each! $ fn (sid socket)
              let
                  db $ :db reel
                  records $ :records reel
                  session $ get-in db ([] :sessions sid)
                  old-store $ or (get @*client-caches sid) nil
                  new-store $ twig-container db session records
                  changes $ diff-twig old-store new-store
                    {} $ :key :id
                when config/dev? $ println "\"Changes for" sid "\":" changes (count records)
                if
                  not= changes $ []
                  do
                    wss-send! sid $ {} (:kind :patch) (:data changes)
                    swap! *client-caches assoc sid new-store
            new-twig-loop!
        |*client-caches $ quote
          defatom *client-caches $ {}
        |on-exit! $ quote
          defn on-exit! (code _) (persist-db!)
            ; println "\"exit code is:" $ pr-str code
            js/process.exit
        |storage-file $ quote
          def storage-file $ path/join js/__dirname (:storage-file config/site)
        |*proxied-updater $ quote
          defatom *proxied-updater updater $ ; "\"wss event handlers has closures"
        |*reel $ quote
          defatom *reel $ merge reel-schema
            {} (:base @*initial-db) (:db @*initial-db)
        |*initial-db $ quote
          defatom *initial-db $ merge-local-edn! schema/database storage-file
            fn (found?)
              if found? (println "\"Found local EDN data") (println "\"Found no data")
        |persist-db! $ quote
          defn persist-db! () $ let
              file-content $ format-cirru-edn
                assoc (:db @*reel) :sessions $ {}
              storage-path storage-file
              backup-path $ get-backup-path!
            write-mildly! storage-path file-content
            write-mildly! backup-path file-content
        |reload! $ quote
          defn reload! () (println "\"Code updated9.") (clear-twig-caches!) (reset! *proxied-updater updater)
            reset! *reel $ refresh-reel @*reel @*initial-db updater
            js/clearTimeout @*loop-trigger
            render-loop! *loop-trigger
            sync-clients! @*reader-reel
        |*reader-reel $ quote (defatom *reader-reel @*reel)
        |render-loop! $ quote
          defn render-loop! (*loop)
            when
              not $ identical? @*reader-reel @*reel
              reset! *reader-reel @*reel
              sync-clients! @*reader-reel
            reset! *loop $ delay! 0.2
              fn () $ render-loop! *loop
      :proc $ quote ()
