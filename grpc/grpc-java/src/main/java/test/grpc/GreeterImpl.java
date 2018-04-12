package test.grpc;

import io.grpc.stub.StreamObserver;
import test.grpc.proto.GreeterGrpc;
import test.grpc.proto.HelloReply;
import test.grpc.proto.HelloRequest;

public class GreeterImpl extends GreeterGrpc.GreeterImplBase {
	@Override
	public void sayHello(HelloRequest req,
			StreamObserver<HelloReply> responseObserver) {
		HelloReply reply =
				HelloReply.newBuilder()
				.setMessage("Hello " + req.getName()).build();
		responseObserver.onNext(reply);
		responseObserver.onCompleted();
	}
}