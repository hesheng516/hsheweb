package com.hshe.service;

import java.util.List;
import java.util.Map;

import org.springframework.cloud.netflix.feign.FeignClient;
import org.springframework.web.bind.annotation.RequestMapping;

@FeignClient(value="sysman")
public interface IOrderFeignService {

	/**
	 * @author 何生
	 * 通过feign调用sysman服务
	 * @return List<Map<String,Object>>
	 */
	@RequestMapping("/findUserList") 
	public List<Map<String,Object>> findUserListByOrder();
}
