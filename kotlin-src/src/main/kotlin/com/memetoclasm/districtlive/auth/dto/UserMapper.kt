package com.memetoclasm.districtlive.auth.dto

import com.memetoclasm.districtlive.auth.jpa.UserEntity
import org.mapstruct.Mapper
import org.mapstruct.factory.Mappers

@Mapper(componentModel = "spring")
interface UserMapper {
    companion object {
        val INSTANCE: UserMapper = Mappers.getMapper(UserMapper::class.java)
    }
    fun toEntity(user: User): UserEntity
    fun toUser(entity: UserEntity): User
    fun toUserResponse(entity: UserEntity): UserResponse
}