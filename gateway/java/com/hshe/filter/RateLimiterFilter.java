package com.hshe.filter;

import java.io.IOException;

import javax.servlet.http.HttpServletRequest;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import com.google.common.util.concurrent.RateLimiter;
import com.netflix.zuul.ZuulFilter;
import com.netflix.zuul.context.RequestContext; 

/**
 * 
 * @author 何生
 *
 */

@Component
public class RateLimiterFilter extends ZuulFilter {

	// 每秒产生1000个令牌

	private static final RateLimiter RATE_LIMITER = RateLimiter.create(2); 
	
	/**
	 * filterType : filter类型,分为pre、error、post、 route pre: 请求执行之前filter route:
	 * 处理请求，进行路由 post: 请求处理完成后执行的filter error: 出现错误时执行的filter
	 */
	@Override
	public String filterType() {
		// return PRE_TYPE;
		return "pre";
	}

	/**
	 * filterOrder: filter执行顺序，通过数字指定，数字越小，执行顺序越先
	 */
	@Override
	public int filterOrder() {
		return -4;
	}

	/**
	 * shouldFilter: filter是否需要执行 true执行 false 不执行
	 */
	@Override
	public boolean shouldFilter() {
		RequestContext requestContext = RequestContext.getCurrentContext();
		HttpServletRequest request = requestContext.getRequest();

		// 接口限流
		if ("/sysman/findUserList".equalsIgnoreCase(request.getRequestURI())) {
			return true;
		}
		return false;
	}

	/**
	 * run : filter具体逻辑（上面为true那么这里就是具体执行逻辑）
	 */
	@Override
	public Object run() {
		RequestContext requestContext = RequestContext.getCurrentContext();
		System.out.println("进入了。。。");
		 
		//System.out.println("当前令牌数。。。"+this.storedPermits));
		// 就相当于每调用一次tryAcquire()方法，令牌数量减1，当1000个用完后，那么后面进来的用户无法访问上面接口
		// 当然这里只写类上面一个接口，可以这么写，实际可以在这里要加一层接口判断。
		if (!RATE_LIMITER.tryAcquire()) {

			requestContext.setSendZuulResponse(false);
			// HttpStatus.TOO_MANY_REQUESTS.value()里面有静态代码常量
			System.out.println("无令牌");
			requestContext.setResponseStatusCode(HttpStatus.TOO_MANY_REQUESTS.value());
			try {

				requestContext.getResponse().setContentType("text/xml; charset=utf-8");
				requestContext.getResponse().setCharacterEncoding("utf-8");
				requestContext.getResponse().getWriter().write("限流了");
				System.out.println("限流了");
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

		}
		return null;
	}
}
