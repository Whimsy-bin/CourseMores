package com.moham.coursemores.common.auth.oauth2;

import com.moham.coursemores.common.auth.PrincipalDetails;
import com.moham.coursemores.domain.User;
import com.moham.coursemores.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class PrincipalOauth2UserService extends DefaultOAuth2UserService {

    private final UserRepository userRepository;

    private static final Logger logger = LoggerFactory.getLogger(PrincipalOauth2UserService.class);

    // userRequest 는 code를 받아서 accessToken을 응답 받은 객체
    @Override
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        OAuth2User oAuth2User = super.loadUser(userRequest); // google의 회원 프로필 조회

        // code를 통해 구성한 정보
        logger.info("userRequest clientRegistration : " + userRequest.getClientRegistration());
        // token을 통해 응답받은 회원정보
        logger.info("oAuth2User : " + oAuth2User);

        return processOAuth2User(userRequest, oAuth2User);
    }

    private OAuth2User processOAuth2User(OAuth2UserRequest userRequest, OAuth2User oAuth2User) throws OAuth2AuthenticationException{

        // Attribute를 파싱해서 공통 객체로 묶는다. 관리가 편함.
        OAuth2UserInfo oAuth2UserInfo = null;
        if (userRequest.getClientRegistration().getRegistrationId().equals("google")) {
            logger.info("구글 로그인 요청");
            oAuth2UserInfo = new GoogleUserInfo(oAuth2User.getAttributes());
        }
        else if (userRequest.getClientRegistration().getRegistrationId().equals("kakao")){
            logger.info("카카오톡 로그인 요청");
            oAuth2UserInfo = new KakaoUserInfo((Map)oAuth2User.getAttributes());
        }else {
            logger.warn("지원하지 않는 로그인 요청입니다");
            throw new NullPointerException();
        }

        // 소셜 로그인 정보를 바탕으로 유저 조회
        Optional<User> userOptional =
                userRepository.findByProviderAndProviderId(oAuth2UserInfo.getProvider(), oAuth2UserInfo.getProviderId());

        User user = null;
        if (userOptional.isPresent()) { // 유저가 존재하면 그대로 가져옴
            logger.debug("소셜 로그인 - 로그인");
            user = userOptional.get();
        }
        else { // 소셜 로그인 유저가 존재하지 않다면
            if(oAuth2UserInfo.getEmail() == null){
                logger.warn("이메일 동의를 하지 않아 회원가입이 불가능합니다.");
                throw new OAuth2AuthenticationException("이메일 동의를 하지 않아 회원가입이 불가능합니다.");
            }
            else{
                logger.debug("소셜 로그인 - 회원가입");
                // user의 패스워드가 null이기 때문에 OAuth 유저는 일반적인 로그인을 할 수 없음.
                user = userRepository.save(User.builder()
                        .email(oAuth2UserInfo.getEmail())
                        .provider(oAuth2UserInfo.getProvider())
                        .providerId(oAuth2UserInfo.getProviderId())
                        .roles("ROLE_USER")
                        .build());
            }
        }

        return new PrincipalDetails(user, oAuth2User.getAttributes());
    }
}
