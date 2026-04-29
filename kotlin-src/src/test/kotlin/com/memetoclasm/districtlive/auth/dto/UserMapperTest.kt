package com.memetoclasm.districtlive.auth.dto

import com.memetoclasm.districtlive.auth.jpa.AuthProvider
import com.memetoclasm.districtlive.auth.jpa.UserEntity
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import java.time.Instant


class UserMapperTest {

    val userMapper: UserMapper = UserMapper.INSTANCE

    @Test
    fun testEntityToUserMapping() {
        val entity = UserEntity(
            email = "ibcoleman@gmail.com",
            authProvider = AuthProvider.LOCAL,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
            passwordHash = "hashedPassword"
        )

        val user = userMapper.toUser(entity)

        assertEquals(entity.email, user.email)
        assertEquals(entity.authProvider, user.authProvider)
        assertEquals(entity.email, user.email)
        assertEquals(entity.createdAt, user.createdAt)
        assertEquals(entity.updatedAt, user.updatedAt)
    }

    @Test
    fun testUserToEntityMapping() {
        val user = User(
            email = "ibcoleman@gmail.com",
            authProvider = AuthProvider.LOCAL,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
            passwordHash = "hashedPassword"
        )


        val entity = userMapper.toEntity(user)

        assertEquals(user.email, entity.email)
        assertEquals(user.authProvider, entity.authProvider)
        assertEquals(user.email, entity.email)
        assertEquals(user.createdAt, entity.createdAt)
        assertEquals(user.updatedAt, entity.updatedAt)
        assertEquals(user.passwordHash,entity.passwordHash)
    }

    @Test
    fun testKotlinCopySemantics() {
        val user = User(
            email = "ibcoleman@gmail.com",
            authProvider = AuthProvider.LOCAL,
            createdAt = Instant.now(),
            updatedAt = Instant.now(),
            passwordHash = "hashedPassword"
        )

        val entity = userMapper.toEntity(user)

        assertEquals(user.email, entity.email)
        assertEquals(user.authProvider, entity.authProvider)
        assertEquals(user.email, entity.email)
        assertEquals(user.createdAt, entity.createdAt)
        assertEquals(user.updatedAt, entity.updatedAt)
        assertEquals(user.passwordHash,entity.passwordHash)

        val now = Instant.now()

        val user2 = user.copy(createdAt = now, email="foo@bar.boz")

        val entity2 = userMapper.toEntity(user2)
        assertEquals(user2.email, entity2.email)
        assertEquals(user2.authProvider, entity2.authProvider)
        assertEquals(user2.email, entity2.email)
        assertEquals(user2.createdAt, entity2.createdAt)
        assertEquals(user2.updatedAt, entity2.updatedAt)
        assertEquals(user2.passwordHash,entity2.passwordHash)


    }

}