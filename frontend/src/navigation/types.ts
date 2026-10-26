import type { NavigatorScreenParams } from '@react-navigation/native';
import type {
  AuthRouteName,
  GroupTabRouteName,
  MainRouteName,
  RunTabRouteName,
} from './routes';

export type RunStackParamList = Record<RunTabRouteName, undefined>;
export type GroupStackParamList = Record<GroupTabRouteName, undefined>;

export type MainTabParamList = {
  HomeTab: undefined;
  RunTab: NavigatorScreenParams<RunStackParamList> | undefined;
  GroupTab: NavigatorScreenParams<GroupStackParamList> | undefined;
  CommunityTab: undefined;
};

export type RootStackParamList = Record<
  AuthRouteName | MainRouteName,
  undefined
> & {
  MainTabs: NavigatorScreenParams<MainTabParamList> | undefined;
  HealthPoc: undefined;
  ComponentGallery: undefined;
};

declare global {
  namespace ReactNavigation {
    interface RootParamList extends RootStackParamList {}
  }
}
