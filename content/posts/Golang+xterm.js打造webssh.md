---
title: "Golang+xterm.js打造webssh"
date: 2022-09-24T10:56:46+08:00
categories:
  - 程序天地
tags:
  - Golang
  - xterm.js
  - webssh
---

## 起因

最近在开发中涉及到了 webssh 的需求，于是就有了这篇文章，主要是记录一下开发过程中遇到的问题，以及解决方案。

## 技术架构

- Golang
- [Fiber](https://gofiber.io/)
- Vue
- xterm.js

## 方案

主要是希望前端通过 websocket 连接后端，后端通过 ssh 连接远程服务器，然后将两者的数据流进行转发，这样就实现了 webssh 的功能。

## 前端部分代码

```vue
<template>
  <div id="xterm" class="xterm" />
</template>
<script>
import "xterm/css/xterm.css";
import { Terminal } from "xterm";
import { FitAddon } from "xterm-addon-fit";
import { AttachAddon } from "xterm-addon-attach";

export default {
  name: "Terminal",
  props: {
    url: {
      type: String,
      default: "",
    },
    visible: {
      type: Boolean,
      default: false,
    },
  },
  watch: {
    visible: {
      handler(value) {
        if (
          value &&
          this.socket !== undefined &&
          this.socket.readyState === 3
        ) {
          this.initSocket();
        }
      },
    },
    wsUrl: {
      handler(value) {
        this.initSocket();
      },
    },
  },
  mounted() {
    this.initSocket();
  },
  beforeDestroy() {
    this.socket.close();
    this.term.dispose();
  },
  methods: {
    initTerm() {
      const term = new Terminal({
        fontSize: 14,
        cursorBlink: true,
      });
      const attachAddon = new AttachAddon(this.socket);
      const fitAddon = new FitAddon();
      term.loadAddon(attachAddon);
      term.loadAddon(fitAddon);
      term.open(document.getElementById("xterm"));
      fitAddon.fit();
      term.focus();
      this.term = term;
    },
    initSocket() {
      this.socket = new WebSocket(this.url);
      this.socketOnClose();
      this.socketOnOpen();
      this.socketOnError();
    },
    socketOnOpen() {
      this.socket.onopen = () => {
        // 链接成功后
        this.initTerm();
      };
    },
    socketOnClose() {
      this.socket.onclose = () => {
        this.$emit("terminalClose");
        this.term.dispose();
      };
    },
    socketOnError() {
      this.socket.onerror = () => {
        // console.log('socket 链接失败')
      };
    },
  },
};
</script>

<style scoped>
.xterm {
  height: 600px;
}
</style>
```

## 后端部分代码

```go
package api

import (
 "context"
 "github.com/gofiber/websocket/v2"
 "github.com/google/uuid"
 "github.com/helloyi/go-sshclient"
 log "github.com/sirupsen/logrus"
 "gitlab.com/merico-dev/DevOpsPublic/brooder/db"
 "gitlab.com/merico-dev/DevOpsPublic/brooder/services"
 "golang.org/x/crypto/ssh"
 "io"
)

type WsReaderWriter struct {
 *websocket.Conn
}

func (w *WsReaderWriter) Write(p []byte) (n int, err error) {
 writer, err := w.Conn.NextWriter(websocket.TextMessage)
 if err != nil {
  return 0, err
 }
 defer writer.Close()
 return writer.Write(p)
}

func (w *WsReaderWriter) Read(p []byte) (n int, err error) {
 var msgType int
 var reader io.Reader
 for {
  msgType, reader, err = w.Conn.NextReader()
  if err != nil {
   return 0, err
  }
  if msgType != websocket.TextMessage {
   continue
  }
  return reader.Read(p)
 }
}

func Shell(c *websocket.Conn) {
 uid, err := uuid.Parse(c.Params("uid"))
 if err != nil {
  log.Error(err)
 }
 mc := db.Client.Machine.GetX(context.Background(), uid)
 service, err := services.NewSSHService(mc.MachineIP)
 if err != nil {
  log.Error(err)
 }
 config := &sshclient.TerminalConfig{
  Term:   "xterm",
  Height: 40,
  Weight: 80,
  Modes: ssh.TerminalModes{
   ssh.ECHO:          1,
   ssh.TTY_OP_ISPEED: 14400,
   ssh.TTY_OP_OSPEED: 14400,
  },
 }
 rw := &WsReaderWriter{c}
 if err = service.Client().Terminal(config).SetStdio(rw, rw, rw).Start(); err != nil {
  log.Error(err)
 }
}
```
