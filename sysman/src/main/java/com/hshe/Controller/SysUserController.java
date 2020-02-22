package com.hshe.Controller;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class SysUserController {

	@RequestMapping("/findUserList")
	public List<Map<String, Object>> findUserList() {
		List<Map<String, Object>> lstMap = new ArrayList<Map<String, Object>>();

		Map<String, Object> map = new HashMap<String, Object>();

		map.put("username", "何生");
		map.put("age", 30);
		map.put("address", "安徽省合肥市");
		lstMap.add(map);

		map = new HashMap<String, Object>();
		map.put("username", "比尔盖茨");
		map.put("age", 70);
		map.put("address", "美国华盛顿");
		lstMap.add(map);

		map = new HashMap<String, Object>();
		map.put("username", "马云");
		map.put("age", 60);
		map.put("address", "浙江省杭州市");
		lstMap.add(map);

		return lstMap;
	}
}
