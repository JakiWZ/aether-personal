package io.github.jakiwz.aether.shared.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
class OpenApiConfig {

    @Bean
    OpenAPI aetherOpenApi() {
        return new OpenAPI().info(new Info()
                .title("AETHER - Mars Operations Platform API")
                .description("REST API for colonies, crew, missions, fleet, logistics and incidents. "
                        + "Errors follow RFC 9457 Problem Details with a stable `code` property.")
                .version("v1")
                .license(new License().name("Educational capstone")));
    }
}
