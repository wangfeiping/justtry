### grpc-go 笔记

签出工程  
$ git clone https://github.com/grpc/grpc-go.git

创建软连接  
$ ln -s $GOPATH/src/github.com/grpc/grpc-go/ $GOPATH/src/google.golang.org/grpc

签出工程（会签出依赖工程）  
$ go get github.com/grpc/grpc-go  
部分相关依赖无法签出报错

手动部署获取依赖项目，并创建软连接  
$ go get github.com/golang/net

$ ln -s $GOPATH/src/github.com/golang/net $GOPATH/src/golang.org/x/

$ go get github.com/golang/text

$ ln -s $GOPATH/src/github.com/golang/text $GOPATH/src/golang.org/x/

$ go get github.com/google/go-genproto

$ ln -s $GOPATH/src/github.com/google/go-genproto/ $GOPATH/src/google.golang.org/genproto

编译依赖工具  
$ go get -u github.com/golang/protobuf

$ cd $GOPATH/src/github.com/protobuf/protoc-gen-go

编译  
$ go install

生成proto 相关代码  
$ protoc --go_out=plugins=grpc:. *.proto

编译服务端  
$ cd $GOPATH/src/google.golang.org/grpc/examples/helloworld/greeter_server

$ go install

启动服务端  
$ greeter_server

编译客户端  
$ cd $GOPATH/src/google.golang.org/grpc/examples/helloworld/greeter_client

$ go install
