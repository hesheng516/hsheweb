package com.hshe.service.impl;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.hshe.service.IOrderService;

@Service
public class OrderService implements IOrderService {

	@Autowired
	private RestTemplate restTemplate;

	@SuppressWarnings("unchecked")
	@Override
	public List<Map<String, Object>> findUserListByOrder() {

		return restTemplate.getForObject("http://sysman/findUserList", List.class);

	}

}
