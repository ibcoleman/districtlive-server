package com.memetoclasm.districtlive

import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.core.userdetails.User
import org.springframework.security.crypto.factory.PasswordEncoderFactories
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.security.provisioning.InMemoryUserDetailsManager
import org.springframework.security.web.SecurityFilterChain

@Configuration
@EnableWebSecurity
class SecurityConfig(
    @Value("\${districtlive.admin.username}") private val adminUsername: String,
    @Value("\${districtlive.admin.password}") private val adminPassword: String
) {

    @Bean
    fun securityFilterChain(http: HttpSecurity): SecurityFilterChain {
        http
            .csrf { it.disable() } // Disable CSRF for REST API
            .authorizeHttpRequests { auth ->
                auth
                    .requestMatchers("/api/auth/register", "/api/auth/login").permitAll()
                    .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                    .requestMatchers("/actuator/**").permitAll() // Allow actuator endpoints
                    .requestMatchers("/api/events/**").permitAll()
                    .requestMatchers("/api/venues/**").permitAll()
                    .requestMatchers("/api/artists/**").permitAll()
                    .requestMatchers("/api/featured/**").permitAll()
                    .requestMatchers("/api/version").permitAll()
                    .requestMatchers("/api/admin/**").authenticated()
                    .anyRequest().authenticated()
            }
            .httpBasic { } // Keep basic auth for other endpoints if needed

        return http.build()
    }

    @Bean
    fun passwordEncoder(): PasswordEncoder {
        return PasswordEncoderFactories.createDelegatingPasswordEncoder()
    }

    @Bean
    fun inMemoryUserDetailsManager(passwordEncoder: PasswordEncoder): InMemoryUserDetailsManager {
        val admin = User.builder()
            .username(adminUsername)
            .password(passwordEncoder.encode(adminPassword))
            .roles("ADMIN")
            .build()
        return InMemoryUserDetailsManager(admin)
    }
}