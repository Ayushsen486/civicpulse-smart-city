export interface Ward {
  id: string;
  name: string;
  wardNumber: number;
  code: string;
  active: boolean;
  boundaryWkt?: string;
}

export interface CreateWardRequest {
  name: string;
  wardNumber: number;
  code: string;
  boundaryWkt: string;
}

export interface UpdateWardRequest {
  name?: string;
  wardNumber?: number;
  code?: string;
  active?: boolean;
  boundaryWkt?: string;
}
