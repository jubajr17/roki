import userSocket from "./user_socket"
import {Presence} from "phoenix"

let channel = userSocket.channel("room:lobby", {})
let presence = new Presence(channel)
let chatInput         = document.querySelector("#chat-input")
let messagesContainer = document.querySelector("#chat-messages")

function renderOnlineUsers(presence) {
    let response = ""

    presence.list((id, {metas: [first, ...rest]}) => {
        response += `<li>${first.email}</li>`
    })

    document.querySelector("#online-users").innerHTML = response
}

presence.onSync(() => renderOnlineUsers(presence))

chatInput.addEventListener("keypress", event => {
    if (event.key === 'Enter') {
        let value = chatInput.value.trim()
        if (value) {
            channel.push("new_msg", {body: value})
        }
        chatInput.value = ""
    }
})

channel.on("new_msg", payload => {
    let message = document.createElement("p")
    message.style.color = payload.color
    let name = document.createElement("text")
    name.classList.add('name')
    name.innerText = `${payload.email}: `
    message.appendChild(name)
    message.appendChild(document.createTextNode(payload.body))
    messagesContainer.appendChild(message)
})

channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })
