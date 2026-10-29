import React from 'react';
import { useNavigation } from '@react-navigation/native';
import { AppText, Button, Card } from '../components';
import { appConfig } from '../config';

export function SettingsPreview() {
  const navigation = useNavigation();
  return (
    <>
      {appConfig.developerMenu ? (
        <Card>
          <AppText variant="bodyStrong">개발용</AppText>
          <Button
            title="공통 컴포넌트 미리보기"
            variant="secondary"
            size="medium"
            onPress={() => navigation.navigate('ComponentGallery')}
          />
          <Button
            title="건강 데이터 PoC"
            variant="secondary"
            size="medium"
            onPress={() => navigation.navigate('HealthPoc')}
          />
        </Card>
      ) : null}
    </>
  );
}
