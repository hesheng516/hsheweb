package com.hshe.Controller;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.hshe.service.IOrderFeignService;

@RestController
public class OrderFeignController {
	@Autowired
	IOrderFeignService orderFeignService;
	
	@RequestMapping("/findUserListByFeign")
	public List<Map<String,Object>> findUserListByFeign(){
		System.out.println("通过fegin服务调用sysman服务读取用户列表");
		return orderFeignService.findUserListByOrder();
	}
}
