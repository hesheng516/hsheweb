package com.hshe;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.EnableEurekaClient;

@SpringBootApplication
@EnableEurekaClient
public class SysMangerApplication {

	public static void main(String[] args) {

		SpringApplication.run(SysMangerApplication.class, args);
	}

}
