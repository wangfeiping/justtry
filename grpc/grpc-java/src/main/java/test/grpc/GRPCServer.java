package test.grpc;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import io.grpc.Server;
import io.grpc.ServerBuilder;

/**
 * https://grpc.io/docs/tutorials/basic/java.html
 * https://time.geekbang.org/column/article/4435
 * @author wangfp
 *
 */

@SpringBootApplication
public class GRPCServer {

	public static void main(String[] args){
		SpringApplication.run(GRPCServer.class, args);
		
		/* The port on which the server should run */
		int port = 50051;
		try{
			Server server = ServerBuilder.forPort(port)
					.addService(new GreeterImpl()).build()
					.start();
		}catch(Exception e){
			e.printStackTrace();
		}
	}
}
