import { Priority } from './issue';

export interface Category {
  id: string;
  name: string;
  slug: string;
  description?: string;
  icon?: string;
  color?: string;
  defaultPriority: Priority;
  slaHoursOverride?: number;
  parentCategoryId?: string;
  parentCategoryName?: string;
  active: boolean;
  subCategories?: Category[];
}

export interface CreateCategoryRequest {
  name: string;
  slug: string;
  description?: string;
  icon?: string;
  color?: string;
  defaultPriority: Priority;
  slaHoursOverride?: number;
  parentCategoryId?: string;
}

export interface UpdateCategoryRequest {
  name?: string;
  description?: string;
  icon?: string;
  color?: string;
  defaultPriority?: Priority;
  slaHoursOverride?: number;
  active?: boolean;
}
