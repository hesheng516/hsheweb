package com.hshe.service;

import java.util.List;
import java.util.Map;

public interface IOrderService {

	/**
	 * @author 何生
	 * 通过manager服务调用sysman服务
	 * @return List<Map<String,Object>>ß
	 */
	public List<Map<String,Object>> findUserListByOrder();
}
