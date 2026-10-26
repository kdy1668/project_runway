import type { NavigationProp } from '@react-navigation/native';
import {
  routes,
  type AuthRouteName,
  type GroupTabRouteName,
  type MainRouteName,
  type RouteName,
  type RunTabRouteName,
} from './routes';
import type { RootStackParamList } from './types';

type Navigate = Pick<NavigationProp<RootStackParamList>, 'navigate'>;

// Tab screens live inside MainTabs, so a link to one goes through the tab instead of the root stack.
export function navigateTo(navigation: Navigate, name: RouteName) {
  switch (routes[name].tab) {
    case 'HomeTab':
    case 'CommunityTab':
      navigation.navigate('MainTabs', { screen: routes[name].tab });
      return;
    case 'RunTab':
      navigation.navigate('MainTabs', {
        screen: 'RunTab',
        params: { screen: name as RunTabRouteName },
      });
      return;
    case 'GroupTab':
      navigation.navigate('MainTabs', {
        screen: 'GroupTab',
        params: { screen: name as GroupTabRouteName },
      });
      return;
    default:
      // Every root route takes no params, which the per-name overloads cannot express for a union.
      (navigation.navigate as (screen: AuthRouteName | MainRouteName) => void)(
        name as AuthRouteName | MainRouteName,
      );
  }
}
