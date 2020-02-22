package com.hshe.Controller;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import com.hshe.service.IOrderService;

@RestController
public class OrderController {

	@Autowired
	IOrderService orderService;
	
	@RequestMapping("/findUserListByOrder")
	public List<Map<String,Object>> findUserListByOrder(){
		System.out.println("通过manager服务调用sysman服务读取用户列表");
		return orderService.findUserListByOrder();
	}
	
	@Bean
	@LoadBalanced
	RestTemplate restTemplate() {
		return new RestTemplate();
	}
}
