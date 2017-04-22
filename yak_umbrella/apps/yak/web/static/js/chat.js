let dom = require('dom-tree')
let select = require('dom-select')

let Chat = {
  init(socket, element) {

    if (!element)
      return

    let chatId = element.getAttribute("data-id")

    socket.connect()

    this.onReady(chatId, socket)
  },

  onReady(chatId, socket) {
    let msgContainer = document.getElementById("msg-container")
    let userContainer = document.getElementById("user-container")
    let msgInput = document.getElementById("msg-input")
    let postButton = document.getElementById("msg-submit")
    let chatChannel = socket.channel("chats:" + chatId)

    postButton.addEventListener("click", e => {
      // message payload
      let payload = { body: msgInput.value }

      this.push_message(chatChannel, payload)

      // reset
      msgInput.value = ""
    })

    // probably refactor this out, might no longer be needed
    msgContainer.addEventListener("click", e => {
      e.preventDefault()

    })

    chatChannel.on("new_message", (resp) => {
      chatChannel.params.last_seen_id = resp.id
      this.renderMessage(msgContainer, resp)
    })

    chatChannel.on("new_command", (resp) => {
      this.renderCommand(msgContainer, resp)
    })

    chatChannel.on("new_user", (resp) => {

      let currentUserId = parseInt(userContainer.getAttribute("data-user-id"))

      if(resp.id !== currentUserId)
        this.renderUser(userContainer, resp)
    })

    chatChannel.on("user_left", (resp) => {
      this.refreshUsers(userContainer, resp.users)
    })

    chatChannel.join()
      .receive("ok", resp => {
        let ids = resp.messages.map(msg => msg.id)
        if (ids.length > 0) {
          chatChannel.params.last_seen_id = Math.max(...ids)
        }
        this.renderMessages(msgContainer, resp.messages)
        this.renderUsers(userContainer, resp.users)
      })
      .receive("error", reason => console.log("join failed", reason))
  },

  push_message(channel, payload) {
    // push the message to the channel

    if(payload.body.startsWith("/")) {
      channel.push("new_command", payload)
        .receive("error", e => console.log(e))
    } else {
      channel.push("new_message", payload)
        .receive("error", e => console.log(e))
    }
  },

  esc(str) {
    let div = document.createElement("div")

    dom.add(div, document.createTextNode(str))

    return div.innerHTML
  },

  // renders all msgs on load
  renderMessages(msgContainer, messages) {
    messages.forEach((msg) => { this.renderMessage(msgContainer, msg) })
  },

  // render one msg
  renderMessage(msgContainer, { user, body }) {

    let template = document.createElement("div")

    dom.add(template, `<a href="#" ><b>${this.esc(user.username)}</b>: ${this.esc(body)} </a>`)

    dom.add(msgContainer, template)

    msgContainer.scrollTop = msgContainer.scrollHeight
  },

  renderCommand(msgContainer, { suceeded, result }) {
    
    let template = document.createElement("div")

    if (suceeded) {
      dom.add(template, `<a href="#"><b>Command</b>: ${this.esc(result)}</a>`)
    } else {
      dom.add(template, `<a href="#"><b>Command</b>: No command found.</a>`)
    }

    dom.add(msgContainer, template)

    msgContainer.scrollTop = msgContainer.scrollHeight
  },

  refreshUsers(userContainer, users) {
    // clean the node
    while (userContainer.lastChild) {
        userContainer.removeChild(userContainer.lastChild);
    }
    this.renderUsers(userContainer, users)
  },

  renderUsers(userContainer, users) {
    users.forEach((user) => { this.renderUser(userContainer, user)})
  },

  renderUser(userContainer, user) {

    let template = document.createElement("div")

    dom.add(template, `<a href="#"><b>${this.esc(user.username)}</b></a>`)

    dom.add(userContainer, template)
  }

}

export default Chat
