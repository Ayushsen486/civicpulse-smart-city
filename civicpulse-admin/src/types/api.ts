export interface PageMeta {
  page?: number;
  number?: number;
  size: number;
  totalElements: number;
  totalPages: number;
  hasNext?: boolean;
  hasPrevious?: boolean;
}

export interface ApiMeta {
  timestamp?: string;
  page?: PageMeta;
}

export interface ApiError {
  field?: string;
  message: string;
  code?: string;
}

export interface ApiResponse<T> {
  data: T;
  meta?: ApiMeta;
  errors?: ApiError[];
}
