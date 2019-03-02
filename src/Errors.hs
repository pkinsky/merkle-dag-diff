module Errors where

--------------------------------------------
import           Control.Exception (Exception)
--------------------------------------------
import           HGit.Types (HashPointer, BranchName)
--------------------------------------------

data MerkleTreeLookupError
  = EntityNotFoundInStore HashPointer
  deriving Show

instance Exception MerkleTreeLookupError


data RepoStateError
  = DecodeError
  | BranchNotFound BranchName
  deriving Show

instance Exception RepoStateError

data FileReadError
  = FileReadError FilePath -- tried to read this path but failed (todo better errors? idk lol)
  deriving Show
