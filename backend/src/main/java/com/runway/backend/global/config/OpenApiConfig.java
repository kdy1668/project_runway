package com.runway.backend.global.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
public class OpenApiConfig {

    @Bean
    OpenAPI runWayOpenApi() {
        return new OpenAPI()
                .info(
                        new Info()
                                .title("RunWay API")
                                .description("RunWay 백엔드 API")
                                .version("v0.0.1"));
    }
}
